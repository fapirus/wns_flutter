# wns_flutter

[![Korean Documentation](https://img.shields.io/badge/Language-Korean-blue)](README_ko.md)

A Flutter plugin for packaged Windows apps that need Windows Notification
Service (WNS) channel registration and push event handling.

`wns_flutter` currently targets the classic Partner Center / WNS path for
installed MSIX apps. It does not try to make unpackaged `flutter run -d windows`
behave like a packaged production app.

## Status

Use `0.0.2` or newer for real integration work.

`0.0.1` was the "it compiles, ship the curiosity" release. It is kept for
history, but it should not be used as the basis for an actual WNS integration.

## Available Now

| Area | Support |
| --- | --- |
| Partner Center WNS path | Create and close WNS channels from a packaged Windows app. |
| Package identity | Requires MSIX/package identity at runtime. |
| Foreground push events | Receive raw, badge, and tile push deliveries through `onMessage`. |
| Toast activation | Read launch, click, action, and input activation through `getInitialActivation` and `onActivation`. |
| Typed event models | Handle `WnsRawMessage`, `WnsBadgeMessage`, `WnsTileMessage`, and `WnsToastActivation`. |
| Notification settings | Read Windows notification settings and open the related settings page. |
| Error handling | Map platform failures to typed `WnsException` classes. |

## Planned

The current public roadmap is intentionally small. The next areas of work are:

- stronger setup and validation documentation
- raw push background handling
- Azure AD / Windows App SDK adapter support

These are planned capabilities, not version promises.

## Installation

```yaml
dependencies:
  wns_flutter: ^0.0.2
```

## Windows Requirements

WNS support in this package assumes all of the following:

- Windows 10 version 1809, build 17763, or later
- an MSIX-installed Windows app
- package identity at runtime
- a Partner Center app registration for the classic WNS path
- a backend that stores the channel URI and sends WNS payloads

The client requests a channel URI. Your backend is responsible for storing that
URI, authenticating with WNS, validating that the URI belongs to
`notify.windows.com`, and sending payloads.

## Quick Start

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

Notification settings are separate from channel initialization:

```dart
final settings = WnsNotificationSettings();
final info = await settings.getInfo();

if (!info.canShowToast && info.canOpenSettings) {
  await settings.openSettingsPage();
}
```

## Event Lifecycle

| App state | API | Event model |
| --- | --- | --- |
| Process alive, raw push received | `client.onMessage` | `WnsRawMessage` |
| Process alive, badge push received | `client.onMessage` | `WnsBadgeMessage` |
| Process alive, tile push received | `client.onMessage` | `WnsTileMessage` |
| App launched from toast | `client.getInitialActivation()` | `WnsToastActivation` |
| Running app opened from toast click/action/input | `client.onActivation` | `WnsToastActivation` |

Foreground toast pushes are activation-only in this package. Windows may display
or store the toast, but the SDK does not emit a toast `onMessage` event before
the user selects or acts on it.

### Suppress Toasts While The App Is Foreground

Foreground toast suppression is opt-in. The default retains normal Windows toast
presentation:

```dart
final client = const WnsClientBuilder().create(
  const PartnerCenterWnsOptions(suppressForegroundToasts: true),
);
```

With this option enabled, the native WNS receive callback checks whether the
foreground window belongs to the receiving process, including its owned dialogs.
If it does, the callback synchronously cancels the toast before Windows displays
a banner or adds a new Notification Center entry. Existing entries are not
removed.

When another app is foreground, the window is minimized, or the process is
closed, cloud toasts retain normal Windows handling. If foreground ownership
cannot be determined, the toast is left visible.

Raw, badge, and tile deliveries are unaffected. A suppressed toast does not emit
an `onMessage` event; keep sending raw updates alongside cloud toasts if the app
also needs immediate in-app state changes. No backend presence tracking is
required.

## Development And Validation

`flutter run -d windows` starts an unpackaged Win32 process. WNS APIs that need
package identity are expected to fail in that mode.

Use this flow instead:

1. Build and package the example or your app as MSIX.
2. Install the package.
3. Launch the installed app.
4. Initialize `WnsClient`.
5. Request a channel URI.
6. Register the channel URI with your backend.
7. Send raw, badge, tile, and toast payloads through WNS.
8. Validate `onMessage`, `getInitialActivation`, and `onActivation`.

## Documentation

- [MSIX and Partner Center setup](docs/windows/msix-wns-setup.md)
- [Message and activation lifecycle](docs/windows/message-lifecycle.md)
- [Manual validation checklist](docs/windows/manual-validation.md)

## Troubleshooting

### `WINRT_ERROR` or `0x80070490`

The app probably has no package identity. Install and launch the MSIX package
before calling WNS APIs.

### Channel creation fails

Confirm the package is installed, Partner Center registration is complete, the
device has network access, and the app is requesting a channel from the installed
package context.

### Toast click does not return to the app

Confirm the toast contains launch arguments and that validation is happening
from the installed app, not from an unpackaged development process.
