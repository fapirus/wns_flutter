# wns_flutter

Windows 알림 서비스(WNS)를 위한 Flutter 플러그인입니다.
Flutter를 사용하여 Windows 애플리케이션의 푸시 알림을 구현하고 알림 설정을 쉽게 관리할 수 있습니다.

## 기능

- **알림 설정**: 시스템 알림 설정 상태 확인 및 설정 페이지 열기.
- **채널 URI**: (예정) 푸시 알림 수신을 위한 WNS 채널 URI 발급.
- **네이티브 연동**: C++/WinRT를 사용하여 최신 Windows 10/11을 완벽하게 지원합니다.

## 시작하기

`pubspec.yaml` 파일에 다음을 추가하세요:

```yaml
dependencies:
  wns_flutter: ^0.0.1
```

## 중요: Windows 앱 아이덴티티 (App Identity)

WNS(Windows Notification Service)를 사용하려면 애플리케이션에 유효한 **패키지 아이덴티티(Package Identity)** 가 있어야 합니다 (예: MSIX로 설치됨).

### 1. 릴리즈 모드 (MSIX)
앱을 MSIX로 패키징하여 배포하는 경우 (`flutter_distributor` 또는 Visual Studio 사용), 플러그인이 자동으로 패키지 아이덴티티를 감지합니다. 별도의 설정이 필요하지 않습니다.

### 2. 디버그 모드 (Unpackaged)
`flutter run -d windows`로 실행할 때, 앱은 패키징되지 않은 일반 Win32 앱으로 실행되며 **아이덴티티가 없습니다**. 이 경우 WNS API 호출 시 `Element not found (0x80070490)` 오류가 발생합니다.

개발 중에 이 문제를 해결하려면 PC에 이미 설치된 다른 앱의 **App User Model ID (AUMID)** 를 빌려와서 초기화해야 합니다.

#### AUMID 찾는 방법
PowerShell을 열고 다음 명령어를 실행하세요:
```powershell
Get-StartApps
```
나타나는 목록에서 `Microsoft.MicrosoftEdge` 등 원하는 AppID를 복사하세요.

#### 초기화 코드
`main()` 함수에서 **디버깅용으로만** `WindowsNotificationService.instance.initialize`를 호출하세요.

```dart
import 'package:wns_flutter/wns_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 주의: 디버깅 전용입니다. PC에 있는 유효한 AUMID를 입력하세요.
  // 릴리즈 모드에서는 이 코드가 자동으로 무시되므로 안전합니다.
  await WindowsNotificationService.instance.initialize(
    aumId: 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge', // 예시
  );

  runApp(const MyApp());
}
```

## 사용법

### 알림 설정 상태 확인

```dart
final _wnsService = WindowsNotificationService.instance;

try {
  final status = await _wnsService.getNotificationSettingStatus();
  print('상태: ${status.status}'); // authorized, denied 등
} catch (e) {
  print('에러: $e');
}
```

### 설정 페이지 열기

```dart
await WindowsNotificationService.instance.openNotificationSettingPage();
```

## 트러블슈팅

- **에러 `WINRT_ERROR` (0x80070490)**:
  - 원인: 앱에 아이덴티티가 없습니다.
  - 해결: 디버그 모드에서 `WnsFlutter.initialize(aumid: ...)`를 호출하여 유효한 AUMID를 제공했는지 확인하세요.

## 최소 요구 사항

- Windows 10 버전 1809 (Build 17763) 이상.
