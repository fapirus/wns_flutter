# wns_flutter_example

Example app for the `wns_flutter` package.
It demonstrates the packaged WNS flow that the plugin currently supports.

## What the example shows

- Notification setting status lookup
- Opening the Windows notification settings page
- WNS channel URI retrieval
- Initial toast activation lookup
- Foreground toast delivery updates
- Opened-app toast activation updates
- Foreground toast presentation toggle

## MSIX setup

The example includes placeholder `msix_config` values in `pubspec.yaml`.
Replace all of the following with your real values before packaging:

- `publisher_display_name`
- `identity_name`
- `publisher`

The example is intended for packaged WNS validation, not unpackaged
`flutter run -d windows` development.

## How to use it

1. Update the placeholder MSIX metadata with your actual Partner Center values.
2. Build and package the example as MSIX.
3. Install the packaged app.
4. Request a channel URI from the installed app.
5. Send WNS toast payloads from your server and observe the lifecycle fields in the UI.
