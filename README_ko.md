# wns_flutter

[![English Documentation](https://img.shields.io/badge/Language-English-blue)](README.md)

설치형 Windows 앱에서 Windows Notification Service(WNS) 채널을 발급하고,
푸시 이벤트를 Flutter에서 처리하기 위한 플러그인입니다.

현재 `wns_flutter`는 MSIX로 설치된 앱을 대상으로 하는 classic Partner Center /
WNS 경로를 지원합니다. `flutter run -d windows`로 실행한 unpackaged 개발
프로세스를 실제 패키징된 앱처럼 동작하게 만드는 우회 기능은 제공하지 않습니다.

## 현재 상태

실제 연동 작업에는 `0.0.2` 이상을 사용하세요.

`0.0.1`은 "일단 컴파일은 되네"에 가까운 실험적 릴리스였습니다. 기록으로는
남겨두지만, 실제 WNS 연동의 기준점으로 삼지는 않는 것이 좋습니다.

## 현재 제공 기능

| 영역 | 지원 내용 |
| --- | --- |
| Partner Center WNS 경로 | 패키징된 Windows 앱에서 WNS 채널 생성과 종료를 지원합니다. |
| Package identity | 런타임에 MSIX/package identity가 필요합니다. |
| Foreground push 이벤트 | raw, badge, tile push를 `onMessage`로 수신합니다. |
| Toast activation | 앱 실행, 클릭, 액션, 입력 activation을 `getInitialActivation`과 `onActivation`으로 처리합니다. |
| Typed event model | `WnsRawMessage`, `WnsBadgeMessage`, `WnsTileMessage`, `WnsToastActivation`을 제공합니다. |
| 알림 설정 | Windows 알림 설정 조회와 관련 설정 페이지 열기를 지원합니다. |
| 오류 처리 | 플랫폼 실패를 타입이 있는 `WnsException` 계층으로 매핑합니다. |

## 제공 예정

현재 공개 로드맵은 의도적으로 작게 유지합니다. 다음 항목을 우선 검토합니다.

- 설정과 검증 문서 강화
- raw push background 처리
- Azure AD / Windows App SDK adapter 지원

위 항목은 방향성이지 특정 버전 약속은 아닙니다.

## 설치

```yaml
dependencies:
  wns_flutter: ^0.0.2
```

## Windows 요구 사항

이 패키지의 WNS 기능은 다음 조건을 전제로 합니다.

- Windows 10 version 1809, build 17763 이상
- MSIX로 설치된 Windows 앱
- 런타임 package identity
- classic WNS 경로를 위한 Partner Center 앱 등록
- 채널 URI를 저장하고 WNS payload를 전송하는 백엔드

클라이언트는 채널 URI를 요청합니다. 백엔드는 해당 URI를 저장하고, WNS 인증을
수행하고, URI가 `notify.windows.com`에 속하는지 검증하고, payload를 전송해야
합니다.

## 빠른 시작

```dart
import 'package:wns_flutter/wns_flutter.dart';

final client = const WnsClientBuilder().create(
  const PartnerCenterWnsOptions(),
);

await client.initialize();

final channel = await client.requestChannel();
print(channel.uri);
print(channel.expirationTime);

final initialActivation = await client.getInitialActivation();
if (initialActivation case final WnsToastActivation toast) {
  print(toast.arguments);
  print(toast.argumentMap);
}

client.onMessage.listen((message) {
  switch (message) {
    case WnsRawMessage():
      print(message.text);
      print(message.data);
    case WnsBadgeMessage():
      print(message.value);
      print(message.glyph);
    case WnsTileMessage():
      print(message.xml);
  }
});

client.onActivation.listen((activation) {
  switch (activation) {
    case WnsToastActivation():
      print(activation.kind);
      print(activation.arguments);
      print(activation.userInput);
  }
});
```

알림 설정은 채널 초기화와 별개로 사용할 수 있습니다.

```dart
final settings = WnsNotificationSettings();
final info = await settings.getInfo();

if (!info.canShowToast && info.canOpenSettings) {
  await settings.openSettingsPage();
}
```

## 이벤트 생명주기

| 앱 상태 | API | 이벤트 모델 |
| --- | --- | --- |
| 프로세스 실행 중 raw push 수신 | `client.onMessage` | `WnsRawMessage` |
| 프로세스 실행 중 badge push 수신 | `client.onMessage` | `WnsBadgeMessage` |
| 프로세스 실행 중 tile push 수신 | `client.onMessage` | `WnsTileMessage` |
| toast를 통해 앱 실행 | `client.getInitialActivation()` | `WnsToastActivation` |
| 실행 중인 앱이 toast 클릭/액션/입력으로 열림 | `client.onActivation` | `WnsToastActivation` |

foreground toast push는 이 패키지에서 activation-only로 다룹니다. Windows가 toast를
표시하거나 알림 센터에 저장할 수는 있지만, 사용자가 선택하거나 액션을 수행하기 전
SDK가 toast를 `onMessage` 이벤트로 방출하지는 않습니다.

## 개발과 검증

`flutter run -d windows`는 unpackaged Win32 프로세스를 실행합니다. package
identity가 필요한 WNS API는 이 모드에서 실패하는 것이 정상입니다.

대신 다음 흐름으로 검증하세요.

1. 예제 앱 또는 실제 앱을 MSIX로 빌드하고 패키징합니다.
2. 패키지를 설치합니다.
3. 설치된 앱을 실행합니다.
4. `WnsClient`를 초기화합니다.
5. 채널 URI를 요청합니다.
6. 채널 URI를 백엔드에 등록합니다.
7. WNS로 raw, badge, tile, toast payload를 전송합니다.
8. `onMessage`, `getInitialActivation`, `onActivation` 동작을 확인합니다.

## 문서

- [MSIX와 Partner Center 설정](docs/windows/msix-wns-setup.ko.md)
- [메시지와 activation 생명주기](docs/windows/message-lifecycle.ko.md)
- [수동 검증 체크리스트](docs/windows/manual-validation.ko.md)

## 문제 해결

### `WINRT_ERROR` 또는 `0x80070490`

앱에 package identity가 없을 가능성이 큽니다. WNS API를 호출하기 전에 MSIX
패키지를 설치하고, 설치된 앱을 실행했는지 확인하세요.

### 채널 생성 실패

패키지가 설치되어 있는지, Partner Center 등록이 완료되었는지, 네트워크 연결이
정상인지, 설치된 앱 컨텍스트에서 채널을 요청하고 있는지 확인하세요.

### Toast 클릭이 앱으로 돌아오지 않음

toast에 launch arguments가 포함되어 있는지 확인하고, unpackaged 개발 프로세스가
아닌 설치된 앱에서 검증하고 있는지 확인하세요.
