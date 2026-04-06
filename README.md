# wns_flutter

[![Korean Documentation](https://img.shields.io/badge/Language-Korean-blue)](README_ko.md)

Flutter plugin for Windows Notification Service (WNS).
This package targets packaged Windows apps that use MSIX, Partner Center registration, and the classic WNS channel flow.

## Current Status

The current development target is `0.0.2`.
This version focuses on the toast push lifecycle that Flutter developers typically expect from Firebase Cloud Messaging style APIs.

## Features

- Read Windows notification setting status.
- Open the Windows notification settings page.
- Create a WNS channel URI from a packaged Windows app.
- Receive foreground toast deliveries through `onMessage`.
- Read activation payloads through `getInitialMessage` and `onMessageOpenedApp`.
- Control foreground toast presentation through `setForegroundNotificationPresentation`.

## Installation

```yaml
dependencies:
  wns_flutter: ^0.0.2
```

## Windows Requirements

WNS support in this plugin assumes all of the following.

- The app is installed as an MSIX package.
- The app has package identity at runtime.
- The app is registered for WNS in Partner Center.
- The server sends WNS toast payloads to the channel URI issued for the installed app.

`flutter run -d windows` starts an unpackaged Win32 process, so WNS-dependent APIs fail with `0x80070490`.
The plugin does not provide a temporary AUMID workaround.

## Lifecycle Mapping

| App state | Flutter API | Meaning |
| --- | --- | --- |
| Foreground / process alive | `onMessage` | Toast push arrived while the app process was running |
| Terminated -> launched from toast | `getInitialMessage()` | Read the activation payload that launched the app |
| Background / foreground -> toast selected | `onMessageOpenedApp` | Read the activation payload when the running app is opened from a toast |
| Foreground | `setForegroundNotificationPresentation(alert: ...)` | Keep or suppress the default foreground toast |

## Usage

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

## Development Workflow

1. Package and install the app as MSIX.
2. Confirm package identity and Partner Center registration.
3. Request a channel URI from the installed app.
4. Send WNS toast payloads from your server.
5. Validate `onMessage`, `getInitialMessage`, and `onMessageOpenedApp`.

For the packaged setup flow, see [docs/windows/msix-wns-setup.md](docs/windows/msix-wns-setup.md).

## Troubleshooting

- `WINRT_ERROR` (`0x80070490`)
  - Cause: the current process does not have package identity.
  - Fix: install and run the app as MSIX before calling WNS APIs.
- Channel creation fails
  - Cause: package identity, connectivity, or WNS registration is incomplete.
  - Fix: confirm the MSIX install, Partner Center registration, and network connectivity.

## Minimum Requirements

- Windows 10 version 1809 (build 17763) or later.
