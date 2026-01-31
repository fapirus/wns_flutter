# wns_flutter

[![한국어 문서](https://img.shields.io/badge/Language-Korean-blue)](README_ko.md)

Flutter Plugin for Windows Notification Service (WNS).
Easily implement push notifications and manage notification settings for Windows applications using Flutter.

## Features

- **Notification Settings**: Check and open system notification settings.
- **Channel URI**: (Coming Soon) Retrieve WNS Channel URI for push notifications.
- **Native Integration**: Built with C++/WinRT for modern Windows 10/11 support.

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  wns_flutter: ^0.0.1
```

## Important: Windows App Identity

Windows Notification Service (WNS) requires your application to have a valid **Package Identity** (e.g., installed via MSIX).

### 1. Release Mode (MSIX)
When you package your app as an MSIX (using `flutter_distributor` or Visual Studio), the plugin automatically detects the Package Identity. You don't need any extra configuration.

### 2. Debug Mode (Unpackaged)
When running with `flutter run -d windows`, your app runs as an unpackaged Win32 app and **does not have an identity**. This causes WNS APIs to fail with `Element not found (0x80070490)`.

To fix this during development, you must initialize the plugin with a valid **App User Model ID (AUMID)** of an app already installed on your PC.

#### How to find an AUMID?
Open PowerShell and run:
```powershell
Get-StartApps
```
Pick an AppID (e.g., `Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge` or your own registered app).

#### Initialization Code
Call `WindowsNotificationService.instance.initialize` in your `main()` method **only for debugging**:

```dart
import 'package:wns_flutter/wns_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ONLY for Debugging: Use a valid AUMID from your PC.
  // In Release mode, this parameter is ignored automatically.
  await WindowsNotificationService.instance.initialize(
    aumId: 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge', // Example
  );

  runApp(const MyApp());
}
```

## Usage

### Check Notification Status

```dart
final _wnsService = WindowsNotificationService.instance;

try {
  final status = await _wnsService.getNotificationSettingStatus();
  print('Status: ${status.status}'); // authorized, denied, etc.
} catch (e) {
  print('Error: $e');
}
```

### Open Settings Page

```dart
await WindowsNotificationService.instance.openNotificationSettingPage();
```

## Troubleshooting

- **Error `WINRT_ERROR` (0x80070490)**:
  - Cause: The app has no identity.
  - Fix: Ensure you called `WnsFlutter.initialize(aumid: ...)` with a valid AUMID in debug mode.

## Minimum Requirements

- Windows 10, version 1809 (Build 17763) or later.
