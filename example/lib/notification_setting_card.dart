import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

class NotificationSettingCard extends StatefulWidget {
  const NotificationSettingCard({super.key, required this.client});

  final WnsDemoClient client;

  @override
  State<StatefulWidget> createState() => NotificationSettingCardState();
}

class NotificationSettingCardState extends State<NotificationSettingCard> {
  String _statusText = '-';

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
            Text('Notification Setting', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                Expanded(
                  child: Text(
                    _statusText,
                    key: const ValueKey('notification-status-value'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await widget.client
                      .getNotificationSettingStatus();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _statusText = result.toString();
                  });
                } catch (e) {
                  if (context.mounted) {
                    _showErrorDialog(e);
                  }
                }
              },
              child: const Text('Get Status'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await widget.client.openNotificationSettingPage();
                } catch (e) {
                  if (context.mounted) {
                    _showErrorDialog(e);
                  }
                }
              },
              child: const Text('Open Setting'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(Object e) {
    String message = e.toString();
    String? code;

    if (e is WnsException) {
      message = e.message;
      code = e.code;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (code != null) ...[
              Text(
                'Code: $code',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Raw:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              e.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
