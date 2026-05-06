# 메시지와 Activation 생명주기

`wns_flutter`는 push 전달과 사용자 activation을 분리합니다.

foreground 데이터 성격의 전달은 `onMessage`를 사용합니다. toast 상호작용으로 앱을
열거나 실행 중인 앱으로 돌아오는 흐름은 `getInitialActivation()`과 `onActivation`을
사용합니다.

## 생명주기 요약

| 시나리오 | API | 모델 |
| --- | --- | --- |
| 앱 프로세스 실행 중 raw push 도착 | `client.onMessage` | `WnsRawMessage` |
| 앱 프로세스 실행 중 badge push 도착 | `client.onMessage` | `WnsBadgeMessage` |
| 앱 프로세스 실행 중 tile push 도착 | `client.onMessage` | `WnsTileMessage` |
| toast를 통해 앱 실행 | `client.getInitialActivation()` | `WnsToastActivation` |
| 실행 중인 앱이 toast 클릭/액션/입력을 받음 | `client.onActivation` | `WnsToastActivation` |

## Foreground 메시지

`onMessage`는 구체적인 `WnsMessage` 하위 타입을 방출합니다.

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

Raw 메시지는 사용 가능한 경우 text, bytes, 파싱된 문자열 data, 원본 payload를
제공합니다. Badge 메시지는 읽을 수 있는 경우 숫자 값이나 glyph를 제공합니다. Tile
메시지는 XML payload를 제공합니다.

## Toast Activation

Toast payload는 foreground message 이벤트가 아니라 activation으로 처리합니다.

toast가 종료 상태의 앱을 실행한 경우 한 번 읽습니다.

```dart
final activation = await client.getInitialActivation();

if (activation case final WnsToastActivation toast) {
  print(toast.kind);
  print(toast.arguments);
  print(toast.argumentMap);
}
```

앱 프로세스가 이미 실행 중이면 activation stream을 구독합니다.

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

`WnsToastActivation`은 다음 정보를 포함합니다.

- `kind`: launch, action, foreground forward, unknown
- `arguments`: 원본 launch argument 문자열
- `argumentMap`: 파싱 가능한 경우 launch argument map
- `actionId`: 선택한 toast action
- `userInput`: 텍스트 박스 등 사용자 입력 값
- `xml`: 사용 가능한 경우 toast XML
- `data`: 네이티브 payload 필드에서 파생된 추가 문자열 데이터

## Foreground Toast 정책

이 패키지에서 foreground toast push는 activation-only입니다.

Windows가 toast를 표시하고 알림 센터에 보관할 수는 있지만, 사용자가 상호작용하기
전에는 SDK가 해당 toast를 `WnsMessage`로 방출하지 않습니다. 이 정책은 앱이 보는
계약을 다음처럼 명확히 유지합니다.

- `onMessage`: 앱이 foreground raw/badge/tile 전달을 받음
- `onActivation`: 사용자가 toast를 선택하거나 액션을 수행함

## Initial Activation은 일회성입니다

`getInitialActivation()`은 초기 activation payload를 소비합니다. 초기 activation을
읽은 뒤 반복 호출하면 `null`을 반환합니다.

앱이 toast로 실행된 것이 아니라면 이 메서드는 `null`을 반환합니다.
