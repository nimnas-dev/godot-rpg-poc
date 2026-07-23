# Sources and Research Rules

## 근거 우선순위

1. source·target exact version의 Godot 공식 migration guide와 class reference
2. Godot 공식 release note·release policy
3. Godot 공식 GitHub의 merged change·issue·milestone
4. Godot 공식 blog·forum announcement
5. 일반 forum과 외부 사례

하위 근거는 회귀 후보를 찾는 데 사용하고 공식 문서·merged change·최소 재현으로 확인한다. 문서 버전과 조회일을 항상 기록한다.

## 엔진 업데이트

- [Migrating to a new version 4.7](https://docs.godotengine.org/en/4.7/tutorials/migrating/index.html)
- [Godot release policy](https://docs.godotengine.org/en/stable/about/release_policy.html)
- [Godot download archive](https://godotengine.org/download/archive/)
- [Upgrading from Godot 3 to Godot 4](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.html)
- [4.3 to 4.4](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.4.html)
- [4.4 to 4.5](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.5.html)
- [4.5 to 4.6](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.6.html)
- [4.6 to 4.7](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html)
- [UID changes coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)

목표가 4.7이 아니면 URL과 guide chain을 source·target exact version에 맞춘다.

## API와 extension

- [Godot class reference 4.7](https://docs.godotengine.org/en/4.7/classes/index.html)
- [The .gdextension file and compatibility bounds](https://docs.godotengine.org/en/4.7/engine_details/engine_api/gdextension/gdextension_file.html)
- [C# basics 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/c_sharp_basics.html)
- [Project organization and case sensitivity](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html)

## 공식 커뮤니티와 issue

- [godotengine/godot issues](https://github.com/godotengine/godot/issues)
- [godotengine/godot-docs](https://github.com/godotengine/godot-docs)
- [Godot Forum](https://forum.godotengine.org/)

issue·forum을 사용할 때 exact engine version, renderer, host와 최소 재현이 현재 작업과 같은지 확인한다. unresolved issue는 확정 사실이 아니라 위험으로 기록한다.

## Research log

| Source | Version/date | 적용 범위 | 프로젝트 영향 | 검증 |
| --- | --- | --- | --- | --- |
| 공식 URL | 문서 버전·조회일 | API/import/behavior | 사용/N/A | parse/runtime |
