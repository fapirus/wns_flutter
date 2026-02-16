import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';

class NotificationListenerCard extends StatefulWidget {
  const NotificationListenerCard({super.key});

  @override
  State<StatefulWidget> createState() => NotificationListenerCardState();
}

class NotificationListenerCardState extends State<NotificationListenerCard> {
  final _wnsService = WindowsNotificationService.instance;
  StreamSubscription<WindowsNotification>? _subscription;
  WindowsNotification? _lastMessage;
  String _errorText = '-';
  int _messageCount = 0;

  bool get _isListening => _subscription != null;

  @override
  void dispose() {
    _subscription?.cancel();
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
              'Foreground Notification Listener',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Listening: ${_isListening ? 'ON' : 'OFF'}'),
            Text('Message Count: $_messageCount'),
            const SizedBox(height: 8),
            Text('Last Message: ${_lastMessage?.toString() ?? '-'}'),
            const SizedBox(height: 8),
            Text('Last Error: $_errorText'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isListening ? null : _startListening,
                  child: const Text('Start Listening'),
                ),
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : null,
                  child: const Text('Stop Listening'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Call "Get Channel URI" first, then send push from your provider.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _startListening() {
    final subscription = _wnsService.onMessage().listen(
      (message) {
        if (!mounted) return;
        setState(() {
          _lastMessage = message;
          _messageCount += 1;
          _errorText = '-';
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _errorText = error.toString();
        });
      },
    );

    setState(() {
      _subscription = subscription;
    });
  }

  Future<void> _stopListening() async {
    await _subscription?.cancel();
    if (!mounted) return;
    setState(() {
      _subscription = null;
    });
  }
}
