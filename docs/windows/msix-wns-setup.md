# MSIX And Partner Center Setup

This guide describes the packaged Windows setup expected by `wns_flutter`.

The package currently supports the classic Partner Center / WNS path. It expects
your Flutter app to run as an installed MSIX package with package identity.

## Preconditions

- Your app can be packaged and installed as MSIX.
- The installed app has package identity at runtime.
- You have a Partner Center app registration for WNS.
- Your backend can store channel URIs and send WNS payloads.

Do not put WNS server credentials in the Flutter app. The client requests a
channel URI; the backend owns authentication and delivery.

## Package Metadata

Before packaging, make sure the MSIX metadata matches the app registration you
intend to use:

- package identity name
- publisher
- publisher display name
- package version
- app display name
- app icon

The example app may contain placeholder values. Replace them with values from
your own packaging and Partner Center setup before production validation.

## Client Setup

Create a Partner Center client:

```dart
import 'package:wns_flutter/wns_flutter.dart';

final client = const WnsClientBuilder().create(
  const PartnerCenterWnsOptions(),
);
```

Then initialize and request a channel:

```dart
await client.initialize();

final channel = await client.requestChannel();
print(channel.uri);
print(channel.expirationTime);
```

Call `requestChannel()` from the installed app. The returned URI is expected to
be treated as an app/backend registration value, not as a permanent client-side
cache owned by the SDK.

## Backend Responsibilities

Your backend should:

- accept channel URI updates from an authenticated app/user context
- verify that the channel URI belongs to `notify.windows.com`
- store the latest usable channel URI for the target app/user/device
- authenticate with WNS using your server-side credentials
- send payloads to WNS and log response codes and relevant headers
- stop using expired or rejected channels and ask the app for a fresh channel

## Validation Flow

1. Build the Windows app.
2. Package and install it as MSIX.
3. Launch the installed app from the Start menu or package entry point.
4. Initialize `WnsClient`.
5. Request a channel with `requestChannel()`.
6. Send the channel URI to your backend.
7. Send WNS payloads from the backend.
8. Validate client-side events with `onMessage`, `getInitialActivation`, and
   `onActivation`.

## Expected Client Checks

- `requestChannel()` returns a `WnsChannel` with a URI and expiration time.
- Foreground raw pushes emit `WnsRawMessage` through `onMessage`.
- Foreground badge pushes emit `WnsBadgeMessage` through `onMessage`.
- Foreground tile pushes emit `WnsTileMessage` through `onMessage`.
- Toast launch from a terminated app is available through
  `getInitialActivation()`.
- Toast click/action/input while the app is running is emitted through
  `onActivation`.

## Important Notes

`flutter run -d windows` is not the validation path for WNS channel APIs. That
command runs an unpackaged process, so package-identity-dependent calls are
expected to fail.

If you see `0x80070490`, first confirm that you launched the installed MSIX app,
not the unpackaged development runner.
