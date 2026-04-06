# wns_flutter

Windows Notification Service(WNS)를 위한 Flutter 플러그인입니다.
이 패키지는 MSIX로 설치되고 Partner Center 등록이 완료된 packaged Windows 앱을 기준으로 동작합니다.

## 현재 상태

현재 개발 목표 버전은 `0.0.2`입니다.
이번 버전은 FCM과 유사한 사용감을 목표로 toast push lifecycle에 집중합니다.

## 지원 기능

- Windows 알림 설정 상태 조회
- Windows 알림 설정 페이지 열기
- packaged 앱 기준 WNS channel URI 발급
- `onMessage`를 통한 foreground toast 수신
- `getInitialMessage`, `onMessageOpenedApp`를 통한 activation payload 조회
- `setForegroundNotificationPresentation`을 통한 foreground toast 기본 표시 제어

## 설치

```yaml
dependencies:
  wns_flutter: ^0.0.2
```

## Windows 요구 사항

이 플러그인은 아래 조건을 모두 전제로 합니다.

- 앱이 MSIX로 설치되어 있어야 합니다.
- 런타임에 package identity가 있어야 합니다.
- Partner Center에 WNS 등록이 완료되어 있어야 합니다.
- 서버가 설치된 앱의 channel URI로 WNS toast payload를 전송해야 합니다.

`flutter run -d windows`는 unpackaged Win32 프로세스로 실행되기 때문에 WNS API가 `0x80070490`으로 실패합니다.
이 플러그인은 임시 AUMID 우회 경로를 제공하지 않습니다.

## Lifecycle 매핑

| 앱 상태 | Flutter API | 의미 |
| --- | --- | --- |
| Foreground / 프로세스 실행 중 | `onMessage` | 앱 프로세스가 실행 중일 때 toast push 수신 |
| Terminated -> toast로 실행 | `getInitialMessage()` | 앱을 실행시킨 activation payload 복원 |
| Background / foreground -> toast 선택 | `onMessageOpenedApp` | 실행 중인 앱으로 전달된 activation payload 수신 |
| Foreground | `setForegroundNotificationPresentation(alert: ...)` | 기본 foreground toast 표시 유지 또는 억제 |

## 사용 예시

```dart
final service = WindowsNotificationService.instance;

final channel = await service.getChannelUri();
print(channel.uri);

await service.setForegroundNotificationPresentation(alert: true);

final initialMessage = await service.getInitialMessage();
if (initialMessage != null) {
  print(initialMessage.arguments);
}

service.onMessage.listen((message) {
  print(message.arguments);
  print(message.payload.data);
});

service.onMessageOpenedApp.listen((activation) {
  print(activation.arguments);
  print(activation.userInput);
});
```

## 개발 절차

1. 앱을 MSIX로 패키징하고 설치합니다.
2. package identity와 Partner Center 등록 상태를 확인합니다.
3. 설치된 앱에서 channel URI를 발급합니다.
4. 서버에서 WNS toast payload를 전송합니다.
5. `onMessage`, `getInitialMessage`, `onMessageOpenedApp` 동작을 검증합니다.

packaged 설정 절차는 [docs/windows/msix-wns-setup.md](docs/windows/msix-wns-setup.md)를 참고하세요.

## 문제 해결

- `WINRT_ERROR` (`0x80070490`)
  - 원인: 현재 프로세스에 package identity가 없습니다.
  - 해결: 앱을 MSIX로 설치한 뒤 WNS API를 호출하세요.
- Channel 생성 실패
  - 원인: package identity, 네트워크, Partner Center 등록 중 하나가 불완전합니다.
  - 해결: MSIX 설치, Partner Center 등록, 네트워크 상태를 다시 확인하세요.

## 최소 요구 사항

- Windows 10 version 1809 (build 17763) 이상
