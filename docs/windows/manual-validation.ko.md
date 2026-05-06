# 수동 검증 체크리스트

설치된 Windows 패키지에서 `wns_flutter`를 검증할 때 이 체크리스트를 사용하세요.

## 빌드와 설치

1. Flutter가 FVM을 통해 실행되는지 확인합니다.

   ```powershell
   fvm flutter --version
   ```

2. 예제 Windows 앱을 빌드합니다.

   ```powershell
   cd example
   fvm flutter build windows
   ```

3. 사용 중인 패키징 흐름으로 앱을 MSIX로 패키징하고 설치합니다.

4. unpackaged Flutter runner가 아니라 설치된 앱을 실행합니다.

## 채널 검증

설치된 앱에서 다음을 확인합니다.

1. `PartnerCenterWnsOptions`로 `WnsClient`를 생성합니다.
2. `initialize()`를 호출합니다.
3. `requestChannel()`을 호출합니다.
4. 반환된 `WnsChannel.uri`가 비어 있지 않은지 확인합니다.
5. `WnsChannel.expirationTime`이 미래 시점인지 확인합니다.
6. URI를 백엔드에 등록합니다.

unpackaged 상태에서 기대되는 실패:

- package identity 관련 오류로 채널 생성 실패
- native details에 `0x80070490`이 포함될 수 있음

## Payload 검증

지원되는 전달 형태를 각각 분리해서 검증합니다.

### Raw Push

앱이 실행 중일 때 raw WNS payload를 전송합니다.

기대 결과:

- `client.onMessage`가 `WnsRawMessage`를 방출합니다.
- `text`, `bytes`, `data`, `rawPayload` 중 사용 가능한 값이 네이티브 payload를
  반영합니다.

### Badge Push

앱이 실행 중일 때 badge payload를 전송합니다.

기대 결과:

- `client.onMessage`가 `WnsBadgeMessage`를 방출합니다.
- `value`, `glyph`, `rawPayload` 중 사용 가능한 값이 badge payload를 반영합니다.
- Windows shell이 OS 동작에 따라 badge 상태를 업데이트합니다.

### Tile Push

앱이 실행 중일 때 tile payload를 전송합니다.

기대 결과:

- `client.onMessage`가 `WnsTileMessage`를 방출합니다.
- `xml` 또는 `rawPayload`가 tile payload를 반영합니다.
- 고정된 tile이 OS 동작에 따라 업데이트됩니다.

### Toast Launch

toast payload를 전송하고 앱을 종료한 뒤 toast를 선택합니다.

기대 결과:

- 설치된 앱이 실행됩니다.
- `getInitialActivation()`이 `WnsToastActivation`을 반환합니다.
- payload에 제공된 경우 `arguments`, `argumentMap`, `userInput`이 일치합니다.

### 실행 중 Toast 클릭 또는 액션

설치된 앱이 이미 실행 중일 때 toast를 전송한 뒤 toast 또는 액션을 선택합니다.

기대 결과:

- `client.onActivation`이 `WnsToastActivation`을 방출합니다.
- native data에 따라 `kind`가 `foregroundForward`, `launch`, `action`, `unknown`
  중 하나로 설정됩니다.
- toast가 제공한 경우 `actionId`와 `userInput`을 사용할 수 있습니다.
- 사용자 상호작용 전에는 toast `WnsMessage`가 방출되지 않습니다.

## 알림 설정

채널 등록과 별개로 알림 설정을 검증합니다.

1. `WnsNotificationSettings`를 생성합니다.
2. `getInfo()`를 호출합니다.
3. `canShowToast`, `canOpenSettings`, display setting이 현재 Windows 알림 설정과
   일치하는지 확인합니다.
4. `openSettingsPage()`를 호출하고 Windows 알림 설정 화면이 열리는지 확인합니다.

## 시각 Payload 도구

toast와 tile XML은 수동 검증 중 Microsoft Notifications Visualizer를 사용하세요.
다음 항목을 확인하는 데 도움이 됩니다.

- XML payload 형태
- 시각 렌더링
- payload 크기 경고
- Flutter 앱을 거치기 전 shell 동작

## 기록할 증거

각 검증에서 다음을 기록하세요.

- package identity와 package version
- 채널 URI 요청 성공 또는 실패
- 채널 만료 시간
- 검증한 payload 유형
- 관찰된 클라이언트 이벤트
- 백엔드에서 받은 WNS 응답 코드와 message id
- native error code 또는 exception details
