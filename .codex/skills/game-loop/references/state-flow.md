# Godot Application State Flow

## Recommended state vocabulary

Use the smallest set matching the game. A typical action RPG may need:

```text
BOOT -> TITLE -> LOADING -> PLAYING
PLAYING <-> PAUSED
PLAYING -> RESULTS -> LOADING or TITLE
PLAYING -> GAME_OVER -> LOADING or TITLE
any recoverable state -> ERROR_RECOVERY -> TITLE
```

Do not create a state for every modal widget. Use nested state only when it changes allowed input, processing, persistence, or transitions.

## Transition table

| From | Command | Guard | Exit work | Entry work | Save policy | Failure fallback |
|---|---|---|---|---|---|---|
| TITLE | start_game | valid profile | close title | load run | profile checkpoint | TITLE + error |
| LOADING | load_complete | resources ready | release loader | activate world | none | ERROR_RECOVERY |
| PLAYING | pause | not transitioning | stop world input | show pause | optional | PLAYING |
| PLAYING | player_died | run active | resolve encounter | show result | run result | GAME_OVER |
| GAME_OVER | restart | teardown complete | clear run state | new run | new checkpoint | TITLE |

Write the real project table instead of copying this example unchanged.

## Godot scene ownership

A maintainable root can use three broad branches:

```text
Main
  ApplicationFlow
  WorldHost
  UIHost
```

- `ApplicationFlow` owns state and transition sequencing.
- `WorldHost` owns the current gameplay world and replaces or removes it.
- `UIHost` shows the view appropriate for state but does not decide state by itself.
- Persistent services remain outside replaceable world scenes only when their lifetime requires it.

Use signals from world and UI to request transitions. The flow owner validates the request and performs it once.

## Pause

- Set `SceneTree.paused` deliberately.
- Mark pause UI as `When Paused` or `Always` as appropriate.
- Confirm which animations, particles, timers, input callbacks and audio should continue.
- Signals can still invoke methods on paused nodes; handlers must guard invalid state.
- Test opening and closing pause repeatedly during attacks, death and scene transition.

## Restart transaction

Treat restart as a transaction:

1. Lock new gameplay commands.
2. Stop spawning and pending asynchronous work.
3. Disconnect external session connections if ownership does not clean them automatically.
4. Remove or reset world state.
5. Reset session-scoped services and random seeds as intended.
6. Instantiate and configure the new world.
7. Restore UI and input.
8. Unlock gameplay commands.

Verify that two rapid restart requests result in one new session.

## Transition tests

- launch without save and with valid/corrupt/old save;
- pause during every important gameplay state;
- death and victory in the same frame;
- restart while projectiles, timers and tweens are active;
- return to title and start a second run;
- app background and resume during loading, playing and pause;
- repeated button presses and touch events;
- resource load failure and safe fallback.
