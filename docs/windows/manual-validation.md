# Manual Validation Checklist

Use this checklist when validating `wns_flutter` against an installed Windows
package.

## Build And Install

1. Confirm Flutter is running through FVM:

   ```powershell
   fvm flutter --version
   ```

2. Build the example Windows app:

   ```powershell
   cd example
   fvm flutter build windows
   ```

3. Package and install the app as MSIX using your packaging workflow.

4. Launch the installed app, not the unpackaged Flutter runner.

## Channel Validation

In the installed app:

1. Create a `WnsClient` with `PartnerCenterWnsOptions`.
2. Call `initialize()`.
3. Call `requestChannel()`.
4. Confirm the returned `WnsChannel.uri` is non-empty.
5. Confirm `WnsChannel.expirationTime` is in the future.
6. Register the URI with your backend.

Expected failure when run unpackaged:

- channel creation fails with a package identity related error
- native details may include `0x80070490`

## Payload Validation

Validate each supported delivery shape separately.

### Raw Push

Send a raw WNS payload while the app is running.

Expected result:

- `client.onMessage` emits `WnsRawMessage`
- `text`, `bytes`, `data`, or `rawPayload` reflects the native payload

### Badge Push

Send a badge payload while the app is running.

Expected result:

- `client.onMessage` emits `WnsBadgeMessage`
- `value`, `glyph`, or `rawPayload` reflects the badge payload
- the Windows shell updates the badge state according to OS behavior

### Tile Push

Send a tile payload while the app is running.

Expected result:

- `client.onMessage` emits `WnsTileMessage`
- `xml` or `rawPayload` reflects the tile payload
- the pinned tile updates according to OS behavior

### Toast Launch

Send a toast payload, close the app, then select the toast.

Expected result:

- the installed app launches
- `getInitialActivation()` returns `WnsToastActivation`
- `arguments`, `argumentMap`, and `userInput` match the toast payload when
  provided

### Toast Click Or Action While Running

Send a toast while the installed app is already running, then select the toast
or one of its actions.

Expected result:

- `client.onActivation` emits `WnsToastActivation`
- `kind` is `foregroundForward`, `launch`, `action`, or `unknown` depending on
  native data
- `actionId` and `userInput` are available when the toast supplied them
- no toast `WnsMessage` is emitted before user interaction

## Notification Settings

Validate settings separately from channel registration:

1. Create `WnsNotificationSettings`.
2. Call `getInfo()`.
3. Confirm `canShowToast`, `canOpenSettings`, and the display setting match the
   current Windows notification configuration.
4. Call `openSettingsPage()` and confirm Windows opens the notification settings
   surface.

## Visual Payload Tools

For toast and tile XML, use Microsoft's Notifications Visualizer during manual
checks. It helps confirm:

- XML payload shape
- visual rendering
- payload size warnings
- shell behavior before involving the Flutter app

## Evidence To Capture

Record the following for each validation pass:

- package identity and package version
- channel URI request success or failure
- channel expiration time
- payload type under test
- client-side event observed
- WNS response code and message id from the backend
- any native error code or exception details
