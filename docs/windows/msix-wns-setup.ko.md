# MSIX와 Partner Center 설정

이 문서는 `wns_flutter`가 기대하는 패키징된 Windows 설정 흐름을 설명합니다.

현재 패키지는 classic Partner Center / WNS 경로를 지원합니다. Flutter 앱은
package identity를 가진 설치형 MSIX 패키지로 실행되어야 합니다.

## 선행 조건

- 앱을 MSIX로 패키징하고 설치할 수 있어야 합니다.
- 설치된 앱이 런타임에 package identity를 가져야 합니다.
- WNS를 위한 Partner Center 앱 등록이 필요합니다.
- 백엔드가 채널 URI를 저장하고 WNS payload를 전송할 수 있어야 합니다.

WNS 서버 자격 증명을 Flutter 앱에 넣지 마세요. 클라이언트는 채널 URI를 요청하고,
백엔드가 인증과 전송을 담당합니다.

## 패키지 메타데이터

패키징하기 전에 MSIX 메타데이터가 사용하려는 앱 등록 정보와 맞는지 확인하세요.

- package identity name
- publisher
- publisher display name
- package version
- app display name
- app icon

예제 앱에는 placeholder 값이 들어 있을 수 있습니다. 운영 검증 전에 실제 패키징 및
Partner Center 설정 값으로 교체하세요.

## 클라이언트 설정

Partner Center 클라이언트를 생성합니다.

```dart
import 'package:wns_flutter/wns_flutter.dart';

final client = const WnsClientBuilder().create(
  const PartnerCenterWnsOptions(),
);
```

초기화 후 채널을 요청합니다.

```dart
await client.initialize();

final channel = await client.requestChannel();
print(channel.uri);
print(channel.expirationTime);
```

`requestChannel()`은 설치된 앱에서 호출해야 합니다. 반환된 URI는 SDK가 영구적으로
소유하는 클라이언트 캐시가 아니라, 앱과 백엔드가 등록하고 갱신해야 하는 값으로
취급하세요.

## 백엔드 책임

백엔드는 다음을 처리해야 합니다.

- 인증된 앱/사용자 컨텍스트에서 채널 URI 업데이트 수신
- 채널 URI가 `notify.windows.com`에 속하는지 검증
- 대상 앱/사용자/디바이스의 최신 사용 가능한 채널 URI 저장
- 서버 측 자격 증명으로 WNS 인증 수행
- WNS payload 전송과 응답 코드 및 관련 헤더 로깅
- 만료되거나 거부된 채널 사용 중단 및 앱에 새 채널 요청 유도

## 검증 흐름

1. Windows 앱을 빌드합니다.
2. 앱을 MSIX로 패키징하고 설치합니다.
3. Start menu 또는 패키지 entry point에서 설치된 앱을 실행합니다.
4. `WnsClient`를 초기화합니다.
5. `requestChannel()`로 채널을 요청합니다.
6. 채널 URI를 백엔드로 전송합니다.
7. 백엔드에서 WNS payload를 전송합니다.
8. `onMessage`, `getInitialActivation`, `onActivation`으로 클라이언트 이벤트를
   확인합니다.

## 기대되는 클라이언트 확인 항목

- `requestChannel()`이 URI와 만료 시간을 가진 `WnsChannel`을 반환합니다.
- foreground raw push는 `onMessage`로 `WnsRawMessage`를 방출합니다.
- foreground badge push는 `onMessage`로 `WnsBadgeMessage`를 방출합니다.
- foreground tile push는 `onMessage`로 `WnsTileMessage`를 방출합니다.
- 종료 상태에서 toast로 앱이 실행되면 `getInitialActivation()`에서 확인할 수
  있습니다.
- 앱 실행 중 toast 클릭/액션/입력은 `onActivation`으로 방출됩니다.

## 중요 메모

`flutter run -d windows`는 WNS 채널 API 검증 경로가 아닙니다. 이 명령은
unpackaged 프로세스를 실행하므로 package identity가 필요한 호출은 실패하는 것이
정상입니다.

`0x80070490`이 보이면 먼저 unpackaged 개발 runner가 아니라 설치된 MSIX 앱을
실행했는지 확인하세요.
