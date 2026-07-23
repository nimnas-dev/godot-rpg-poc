# Web Export와 Hosting

## 1. 호환성 계약

- Godot 4 Web export는 Compatibility renderer와 WebGL 2.0을 기준으로 검증한다.
- Godot 4의 C# 프로젝트는 현재 Web export를 지원하지 않는다는 목표 버전 문서를 확인한다.
- GDExtension을 쓰면 Web용으로 별도 compile하고 extension support·cross-origin isolation 요구를 확인한다.
- single-thread와 threaded export를 의도적으로 선택한다. Godot 4.3+의 기본 single-thread export는 hosting 호환성이 높다.

## 2. Bundle

- entry HTML은 기본적으로 `index.html`을 사용하고 함께 생성된 파일 이름을 임의 변경하지 않는다.
- HTML, `.js`, `.wasm`, PCK와 optional service worker 파일이 모두 배포됐는지 확인한다.
- custom UI는 생성된 HTML을 직접 수정하지 말고 Custom HTML shell로 유지한다.
- Web export ZIP이나 파일 집합은 server 설정 없이 실행 증거가 아니다.

## 3. Hosting

- `file://`가 아닌 local HTTP server와 실제 HTTPS 배포 host에서 검사한다.
- `.wasm`과 compressed asset의 올바른 MIME·content encoding을 확인한다.
- secure context가 필요한 API는 HTTPS에서 검증한다.
- thread 또는 extension support를 켜면 다음 cross-origin isolation header를 확인한다.

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

- header를 제어할 수 없는 host에서 PWA service worker workaround를 쓸 경우에도 HTTPS와 실제 cold load를 검증한다.
- cache/service worker update가 이전 build를 계속 제공하지 않는지 version update 시나리오를 검사한다.

## 4. 브라우저 검증

- 지원 대상 Chromium, Firefox와 Safari에서 browser console·network 오류를 확인한다.
- desktop과 mobile browser에서 resize, orientation, safe area와 DPR을 검사한다.
- 첫 사용자 gesture 전 audio autoplay 제한과 audio unlock UI를 확인한다.
- fullscreen과 pointer capture는 실제 input event에서 요청되는지 확인한다.
- tab background 시 processing pause와 network disconnect 복구를 확인한다.
- keyboard, pointer, touch, virtual keyboard와 gamepad를 범위에 맞게 검사한다.

## 5. 저장과 성능

- `user://` 지속성은 IndexedDB와 browser policy에 의존한다.
- normal, private browsing, iframe/third-party context에서 `OS.is_userfs_persistent()`와 실제 reload 결과를 확인한다.
- 초기 download 크기, cold/warm load, decompression과 peak memory를 측정한다.
- mobile Safari와 저사양 Android browser에서 texture memory와 context loss를 확인한다.
- PWA offline cache가 eviction될 수 있음을 전제로 offline page와 recovery를 검증한다.

## 6. 완료 판정

다음이 모두 있어야 Web runtime-verified로 기록한다.

1. production-equivalent HTTP(S) response headers와 MIME
2. fresh profile의 cold load
3. browser console에 engine·WebGL·network 오류 없음
4. 지원 browser matrix의 입력·audio·save·resize 통과
5. 새 build 배포 후 cache/service worker update 통과
