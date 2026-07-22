#!/usr/bin/env python3
"""Compare RPG combat growth using expectation and Monte Carlo samples."""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from pathlib import Path
from typing import Any


DEFAULT_CONFIG: dict[str, Any] = {
    "levels": 20,
    "seed": 94721,
    "player": {
        "health_base": 120.0,
        "health_growth": 1.08,
        "damage_base": 20.0,
        "damage_growth": 1.09,
        "attacks_per_second": 1.5,
        "accuracy": 0.92,
        "crit_chance": 0.10,
        "crit_multiplier": 1.75,
    },
    "enemy": {
        "health_base": 80.0,
        "health_growth": 1.10,
        "damage_base": 9.0,
        "damage_growth": 1.085,
        "attacks_per_second": 1.0,
        "accuracy": 0.85,
        "crit_chance": 0.05,
        "crit_multiplier": 1.5,
    },
}


def load_config(path: str | None) -> dict[str, Any]:
    if path is None:
        return json.loads(json.dumps(DEFAULT_CONFIG))
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    merged = json.loads(json.dumps(DEFAULT_CONFIG))
    merged.update({key: value for key, value in data.items() if key not in {"player", "enemy"}})
    for actor in ("player", "enemy"):
        merged[actor].update(data.get(actor, {}))
    return merged


def validate_actor(name: str, actor: dict[str, float]) -> None:
    positive = ("health_base", "health_growth", "damage_base", "damage_growth", "attacks_per_second")
    for key in positive:
        if float(actor[key]) <= 0:
            raise ValueError(f"{name}.{key} must be greater than zero")
    for key in ("accuracy", "crit_chance"):
        if not 0 <= float(actor[key]) <= 1:
            raise ValueError(f"{name}.{key} must be between zero and one")
    if float(actor["crit_multiplier"]) < 1:
        raise ValueError(f"{name}.crit_multiplier must be at least one")


def scaled(base: float, growth: float, level: int) -> float:
    return base * growth ** (level - 1)


def expected_dps(actor: dict[str, float], damage: float) -> float:
    crit_factor = 1 + actor["crit_chance"] * (actor["crit_multiplier"] - 1)
    return damage * actor["attacks_per_second"] * actor["accuracy"] * crit_factor


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, math.ceil(fraction * len(ordered)) - 1))
    return ordered[index]


def sample_kill_time(
    rng: random.Random,
    attacker: dict[str, float],
    damage: float,
    target_health: float,
) -> float:
    interval = 1.0 / attacker["attacks_per_second"]
    elapsed = 0.0
    remaining = target_health
    attempts = 0
    while remaining > 0 and attempts < 100000:
        attempts += 1
        elapsed += interval
        if rng.random() > attacker["accuracy"]:
            continue
        hit = damage
        if rng.random() < attacker["crit_chance"]:
            hit *= attacker["crit_multiplier"]
        remaining -= hit
    return elapsed


def simulate(config: dict[str, Any], samples: int) -> list[dict[str, float]]:
    levels = int(config["levels"])
    if levels < 1 or levels > 1000:
        raise ValueError("levels must be between 1 and 1000")
    player = config["player"]
    enemy = config["enemy"]
    validate_actor("player", player)
    validate_actor("enemy", enemy)
    rng = random.Random(int(config.get("seed", 0)))
    rows: list[dict[str, float]] = []

    for level in range(1, levels + 1):
        player_hp = scaled(player["health_base"], player["health_growth"], level)
        player_damage = scaled(player["damage_base"], player["damage_growth"], level)
        enemy_hp = scaled(enemy["health_base"], enemy["health_growth"], level)
        enemy_damage = scaled(enemy["damage_base"], enemy["damage_growth"], level)
        player_dps = expected_dps(player, player_damage)
        enemy_dps = expected_dps(enemy, enemy_damage)
        expected_ttk = enemy_hp / player_dps
        expected_ttd = player_hp / enemy_dps

        ttk_samples = [sample_kill_time(rng, player, player_damage, enemy_hp) for _ in range(samples)]
        ttd_samples = [sample_kill_time(rng, enemy, enemy_damage, player_hp) for _ in range(samples)]
        rows.append(
            {
                "level": level,
                "player_hp": player_hp,
                "enemy_hp": enemy_hp,
                "player_dps": player_dps,
                "enemy_dps": enemy_dps,
                "expected_ttk": expected_ttk,
                "expected_ttd": expected_ttd,
                "safety_ratio": expected_ttd / expected_ttk,
                "ttk_p50": statistics.median(ttk_samples),
                "ttk_p90": percentile(ttk_samples, 0.90),
                "ttd_p10": percentile(ttd_samples, 0.10),
            }
        )
    return rows


def print_table(rows: list[dict[str, float]]) -> None:
    print(" lvl | playerHP enemyHP | playerDPS enemyDPS | expTTK expTTD | safety | TTKp50 TTKp90 TTDp10")
    print("-----+------------------+--------------------+---------------+--------+----------------------")
    for row in rows:
        print(
            f"{int(row['level']):4d} | {row['player_hp']:8.1f} {row['enemy_hp']:7.1f} | "
            f"{row['player_dps']:9.1f} {row['enemy_dps']:8.1f} | "
            f"{row['expected_ttk']:6.2f} {row['expected_ttd']:6.2f} | "
            f"{row['safety_ratio']:6.2f} | {row['ttk_p50']:6.2f} {row['ttk_p90']:6.2f} {row['ttd_p10']:6.2f}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", help="JSON file overriding the default model")
    parser.add_argument("--samples", type=int, default=2000, help="Monte Carlo samples per level")
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()
    if args.samples < 1 or args.samples > 100000:
        parser.error("--samples must be between 1 and 100000")

    try:
        config = load_config(args.config)
        rows = simulate(config, args.samples)
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        parser.error(str(error))

    if args.as_json:
        print(json.dumps({"config": config, "samples": args.samples, "levels": rows}, indent=2))
    else:
        print_table(rows)
        print("\nInterpret with movement, cooldown, range, control and player skill; this is a baseline model.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
