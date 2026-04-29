enum WnsNotificationType {
  raw,
  toast,
  badge,
  tile,
  unknown,
}

enum WnsMessageSource {
  foreground,
  background,
  nativeQueue,
  unknown,
}

enum WnsActivationKind {
  launch,
  action,
  backgroundPush,
  foregroundForward,
  unknown,
}
