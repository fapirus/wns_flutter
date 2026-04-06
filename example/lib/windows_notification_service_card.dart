import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

class WindowsNotificationServiceCard extends StatefulWidget {
  const WindowsNotificationServiceCard({super.key, required this.client});

  final WnsDemoClient client;

  @override
  State<StatefulWidget> createState() => WindowsNotificationServiceCardState();
}

class WindowsNotificationServiceCardState
    extends State<WindowsNotificationServiceCard> {
  StreamSubscription<WindowsIncomingMessage>? _messageSubscription;
  StreamSubscription<WindowsNotificationActivation>? _openedAppSubscription;

  String _channelUri = '-';
  String _initialMessage = 'Loading...';
  String _lastIncomingMessage = '-';
  String _lastOpenedMessage = '-';
  bool _foregroundAlert = true;

  @override
  void initState() {
    super.initState();
    _messageSubscription = widget.client.onMessage.listen((message) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastIncomingMessage = _formatIncomingMessage(message);
      });
    });
    _openedAppSubscription = widget.client.onMessageOpenedApp.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastOpenedMessage = _formatActivation(event);
      });
    });
    _loadInitialMessage();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _openedAppSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Windows Notification Service',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show foreground toast'),
              subtitle: const Text(
                'Turn this off to suppress the default toast while the app is running.',
              ),
              value: _foregroundAlert,
              onChanged: (value) async {
                final previousValue = _foregroundAlert;
                setState(() {
                  _foregroundAlert = value;
                });
                try {
                  await widget.client.setForegroundNotificationPresentation(
                    alert: value,
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _foregroundAlert = previousValue;
                  });
                  _showErrorDialog(error);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await widget.client.getChannelUri();
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _channelUri = result.uri;
                      });
                    } catch (error) {
                      if (context.mounted) {
                        _showErrorDialog(error);
                      }
                    }
                  },
                  child: const Text('Get Channel URI'),
                ),
                OutlinedButton(
                  onPressed: _loadInitialMessage,
                  child: const Text('Refresh Initial Message'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              label: 'Channel URI',
              value: _channelUri,
              valueKey: const ValueKey('channel-uri-value'),
            ),
            const SizedBox(height: 12),
            _InfoBlock(
              label: 'Initial Message',
              value: _initialMessage,
              valueKey: const ValueKey('initial-message-value'),
            ),
            const SizedBox(height: 12),
            _InfoBlock(
              label: 'Last Foreground Message',
              value: _lastIncomingMessage,
              valueKey: const ValueKey('incoming-message-value'),
            ),
            const SizedBox(height: 12),
            _InfoBlock(
              label: 'Last Opened App Event',
              value: _lastOpenedMessage,
              valueKey: const ValueKey('opened-message-value'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitialMessage() async {
    try {
      final message = await widget.client.getInitialMessage();
      if (!mounted) {
        return;
      }
      setState(() {
        _initialMessage =
            message == null ? 'No activation message' : _formatActivation(message);
      });
    } catch (error) {
      if (context.mounted) {
        _showErrorDialog(error);
      }
    }
  }

  String _formatIncomingMessage(WindowsIncomingMessage message) {
    return _formatPayload(
      arguments: message.arguments,
      data: message.payload.data,
      rawPayload: message.payload.rawPayload,
    );
  }

  String _formatActivation(WindowsNotificationActivation activation) {
    return _formatPayload(
      arguments: activation.arguments,
      data: activation.payload.data,
      rawPayload: activation.payload.rawPayload,
      userInput: activation.userInput,
    );
  }

  String _formatPayload({
    required String arguments,
    required Map<String, String> data,
    String? rawPayload,
    Map<String, String> userInput = const <String, String>{},
  }) {
    final buffer = StringBuffer()
      ..write('arguments=')
      ..write(arguments.isEmpty ? '-' : arguments)
      ..write('\n')
      ..write('data=')
      ..write(data.isEmpty ? '{}' : data)
      ..write('\n')
      ..write('userInput=')
      ..write(userInput.isEmpty ? '{}' : userInput);

    if (rawPayload != null && rawPayload.isNotEmpty) {
      buffer
        ..write('\n')
        ..write('rawPayload=')
        ..write(rawPayload);
    }

    return buffer.toString();
  }

  void _showErrorDialog(Object error) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        SelectionArea(
          child: Text(
            value,
            key: valueKey,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
