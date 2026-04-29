import 'package:flutter/material.dart';
import 'package:wns_flutter_example/wns_error_details.dart';
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
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notification Setting',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Check OS notification permission state before validating toast delivery.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusText,
                      key: const ValueKey('notification-status-value'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      final result = await widget.client
                          .getNotificationSettingsInfo();
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _statusText =
                            'status=${result.status}, '
                            'display=${result.displaySetting}, '
                            'canShowToast=${result.canShowToast}';
                      });
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorDialog(e);
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Get Settings Info'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await widget.client.openNotificationSettingPage();
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorDialog(e);
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Setting'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(Object e) {
    final error = formatWnsError(e);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(error.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error.code != null) ...[
              Text(
                'Code: ${error.code}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(error.message),
            if (error.recoveryHint != null) ...[
              const SizedBox(height: 8),
              Text('Recovery: ${error.recoveryHint}'),
            ],
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text('Details: ${error.details}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Raw:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              error.raw,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
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
