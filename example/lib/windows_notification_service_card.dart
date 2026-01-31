import 'package:flutter/material.dart';
import 'package:wns_flutter/wns_flutter.dart';

class WindowsNotificationServiceCard extends StatefulWidget {
  const WindowsNotificationServiceCard({super.key});

  @override
  State<StatefulWidget> createState() => WindowsNotificationServiceCardState();
}

class WindowsNotificationServiceCardState
    extends State<WindowsNotificationServiceCard> {
  final _wnsService = WindowsNotificationService.instance;
  String _channelUri = '-';

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
            const SizedBox(height: 8.0),

            // Channel URI 표시
            const Text('Channel URI:'),
            SelectionArea(
              child: Text(
                _channelUri,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // 채널 URI 발급 버튼
            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await _wnsService.getChannelUri();
                  setState(() {
                    _channelUri = result.toString();
                  });
                } catch (e) {
                  if (context.mounted) _showErrorDialog(e);
                }
              },
              child: const Text('Get Channel URI'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(Object e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
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
