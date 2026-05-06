part of 'wns_activation.dart';

@immutable
class WnsToastActivation extends WnsActivation {
  const WnsToastActivation({
    required this.kind,
    this.arguments = '',
    this.argumentMap = const <String, String>{},
    this.actionId,
    this.userInput = const <String, String>{},
    this.xml,
    this.data = const <String, String>{},
    super.activatedAt,
    super.rawPayload,
  });

  final WnsToastActivationKind kind;
  final String arguments;
  final Map<String, String> argumentMap;
  final String? actionId;
  final Map<String, String> userInput;
  final String? xml;
  final Map<String, String> data;

  @override
  String toString() {
    return 'WnsToastActivation('
        'kind: $kind, '
        'arguments: $arguments, '
        'argumentMap: $argumentMap, '
        'actionId: $actionId, '
        'userInput: $userInput, '
        'xml: $xml, '
        'data: $data, '
        'activatedAt: $activatedAt, '
        'rawPayload: $rawPayload'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WnsToastActivation &&
            other.kind == kind &&
            other.arguments == arguments &&
            mapEquals(other.argumentMap, argumentMap) &&
            other.actionId == actionId &&
            mapEquals(other.userInput, userInput) &&
            other.xml == xml &&
            mapEquals(other.data, data) &&
            other.activatedAt == activatedAt &&
            other.rawPayload == rawPayload;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    arguments,
    Object.hashAllUnordered(argumentMap.entries),
    actionId,
    Object.hashAllUnordered(userInput.entries),
    xml,
    Object.hashAllUnordered(data.entries),
    activatedAt,
    rawPayload,
  );
}
