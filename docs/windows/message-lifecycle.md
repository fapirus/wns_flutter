# Message And Activation Lifecycle

`wns_flutter` separates push delivery from user activation.

Use `onMessage` for foreground data-style deliveries. Use
`getInitialActivation()` and `onActivation` for toast interactions that open or
return to the app.

## Lifecycle Summary

| Scenario | API | Model |
| --- | --- | --- |
| App process is alive and a raw push arrives | `client.onMessage` | `WnsRawMessage` |
| App process is alive and a badge push arrives | `client.onMessage` | `WnsBadgeMessage` |
| App process is alive and a tile push arrives | `client.onMessage` | `WnsTileMessage` |
| App is launched from a toast | `client.getInitialActivation()` | `WnsToastActivation` |
| Running app receives a toast click/action/input | `client.onActivation` | `WnsToastActivation` |

## Foreground Messages

`onMessage` emits concrete `WnsMessage` subclasses:

```dart
client.onMessage.listen((message) {
  switch (message) {
    case WnsRawMessage():
      print(message.text);
      print(message.bytes);
      print(message.data);
    case WnsBadgeMessage():
      print(message.value);
      print(message.glyph);
    case WnsTileMessage():
      print(message.xml);
  }
});
```

Raw messages expose text, bytes, parsed string data, and the original payload
when available. Badge messages expose the numeric value or glyph when those can
be read. Tile messages expose the XML payload.

## Toast Activation

Toast payloads are handled as activations, not foreground message events.

When a toast launches the app from a terminated state, read it once:

```dart
final activation = await client.getInitialActivation();

if (activation case final WnsToastActivation toast) {
  print(toast.kind);
  print(toast.arguments);
  print(toast.argumentMap);
}
```

When the app process is already running, listen for activations:

```dart
client.onActivation.listen((activation) {
  switch (activation) {
    case WnsToastActivation():
      print(activation.kind);
      print(activation.actionId);
      print(activation.userInput);
  }
});
```

`WnsToastActivation` includes:

- `kind`: launch, action, foreground forward, or unknown
- `arguments`: the raw launch argument string
- `argumentMap`: parsed launch arguments when possible
- `actionId`: the selected toast action when available
- `userInput`: text box or other input values
- `xml`: toast XML when available
- `data`: additional string data derived from native payload fields

## Foreground Toast Policy

Foreground toast pushes are activation-only in this package.

Windows may display a toast and keep it in Notification Center, but the SDK does
not emit a `WnsMessage` for that toast before the user interacts with it. This
keeps the app-facing contract aligned around two meanings:

- `onMessage`: the app received a foreground raw/badge/tile delivery
- `onActivation`: the user selected or acted on a toast

## Initial Activation Is One-Time

`getInitialActivation()` consumes the initial activation payload. Repeated calls
return `null` after the initial activation has been read.

If the app was not launched by a toast, the method returns `null`.
