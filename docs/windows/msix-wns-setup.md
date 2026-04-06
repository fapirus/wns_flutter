# MSIX WNS Setup

This guide describes the packaged validation flow expected by `wns_flutter`.

## Preconditions

- You have a Windows app that can be packaged as `MSIX`.
- You have completed the WNS app registration in `Partner Center`.
- You can send WNS toast payloads from your server.

## Example package metadata

The example app includes placeholder `msix_config` values.
Before packaging, replace these values with your real metadata:

- `publisher_display_name`
- `identity_name`
- `publisher`

## Validation flow

1. Build and package the app as `MSIX`.
2. Install the packaged app.
3. Launch the installed app and request a channel URI.
4. Register the channel URI on your server side.
5. Send a WNS toast payload from the server.
6. Validate the lifecycle API results in the app UI.

## Expected checks

- `getChannelUri()` returns a valid URI.
- `onMessage` receives foreground toast payloads.
- `getInitialMessage()` restores activation from a terminated launch.
- `onMessageOpenedApp` receives activation when the process is already running.
- `setForegroundNotificationPresentation(alert: ...)` changes foreground toast behavior.

## Important note

`flutter run -d windows` is not the verification path for this plugin.
The WNS-dependent APIs must be validated from an installed `MSIX` app with package identity.
