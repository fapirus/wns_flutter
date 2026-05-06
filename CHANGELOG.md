## 0.0.2

(en)

* Reworked the package around the Partner Center / classic WNS path for
  packaged Windows apps.
* Added `WnsClient`, `WnsClientBuilder`, and `PartnerCenterWnsOptions`.
* Added typed channel, message, activation, notification settings, and exception
  models.
* Added foreground raw, badge, and tile push event mapping through `onMessage`.
* Added toast launch and running-app activation handling through
  `getInitialActivation()` and `onActivation`.
* Added package identity checks and clearer native error mapping for WNS channel
  creation.
* Added Windows notification settings status lookup and settings page opening.
* Improved the example app to show message and activation timelines separately.
* Added tests for client lifecycle, event decoding, typed exceptions,
  notification settings, and example rendering.

(ko)

* 패키징된 Windows 앱을 위한 Partner Center / classic WNS 경로 중심으로
  패키지 구조를 재정리했습니다.
* `WnsClient`, `WnsClientBuilder`, `PartnerCenterWnsOptions`를 추가했습니다.
* 채널, 메시지, activation, 알림 설정, 예외 처리를 위한 타입이 있는 모델을
  추가했습니다.
* foreground raw, badge, tile push 이벤트를 `onMessage`로 매핑합니다.
* toast launch와 실행 중 앱 activation을 `getInitialActivation()`과
  `onActivation`으로 처리합니다.
* WNS 채널 생성에 필요한 package identity 검사와 네이티브 오류 매핑을
  개선했습니다.
* Windows 알림 설정 상태 조회와 설정 페이지 열기 기능을 추가했습니다.
* 예제 앱에서 message timeline과 activation timeline을 분리해 표시하도록
  개선했습니다.
* 클라이언트 생명주기, 이벤트 디코딩, 타입이 있는 예외, 알림 설정, 예제 렌더링
  테스트를 추가했습니다.

## 0.0.1

(en)

* Initial experimental release for exploring Windows Notification Service (WNS)
  integration from Flutter.
* Kept for history; use `0.0.2` or newer for actual integration work.

(ko)

* Flutter에서 Windows Notification Service(WNS) 연동을 탐색하기 위한 초기
  실험 릴리스입니다.
* 기록용으로 남아 있으며, 실제 연동 작업에는 `0.0.2` 이상을 사용하세요.
