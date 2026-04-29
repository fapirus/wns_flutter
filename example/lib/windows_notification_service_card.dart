import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wns_flutter_example/controller/wns_example_controller.dart';
import 'package:wns_flutter_example/model/wns_event_log_entry.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';
import 'package:wns_flutter_example/wns_error_details.dart';

class WindowsNotificationServiceCard extends StatefulWidget {
  const WindowsNotificationServiceCard({super.key, required this.client});

  final WnsDemoClient client;

  @override
  State<WindowsNotificationServiceCard> createState() =>
      _WindowsNotificationServiceCardState();
}

class _WindowsNotificationServiceCardState
    extends State<WindowsNotificationServiceCard> {
  late final WnsExampleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WnsExampleController(client: widget.client);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        Icons.desktop_windows_outlined,
                        size: 18,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      label: const Text('Packaged Validation Sample'),
                    ),
                    Text(
                      '${_controller.eventLogs.length} events captured',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Windows Notification Service',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Desktop-oriented validation console for SDK initialization, channel retrieval, cold start activation, foreground delivery, and opened-app lifecycle events.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1000;
                    final leftColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ControlsSection(
                          controller: _controller,
                          onError: _showErrorDialog,
                        ),
                        const SizedBox(height: 16),
                        _SummarySection(
                          controller: _controller,
                          onError: _showErrorDialog,
                        ),
                      ],
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftColumn,
                          const SizedBox(height: 16),
                          _EventTimelineSection(entries: _controller.eventLogs),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 340, child: leftColumn),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _EventTimelineSection(
                            entries: _controller.eventLogs,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showErrorDialog(Object error) async {
    if (!mounted) {
      return;
    }

    final details = formatWnsError(error);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(details.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.code != null) ...[
              Text(
                'Code: ${details.code}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(details.message),
            if (details.recoveryHint != null) ...[
              const SizedBox(height: 8),
              Text('Recovery: ${details.recoveryHint}'),
            ],
            if (details.details != null) ...[
              const SizedBox(height: 8),
              Text('Details: ${details.details}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Raw:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              details.raw,
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

class _ControlsSection extends StatelessWidget {
  const _ControlsSection({
    required this.controller,
    required this.onError,
  });

  final WnsExampleController controller;
  final Future<void> Function(Object error) onError;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: 'Controls',
      subtitle: 'Trigger lifecycle reads and adjust foreground presentation.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Show foreground toast'),
              subtitle: const Text(
                'Keep the native foreground toast banner visible while app events are streamed.',
              ),
              value: controller.foregroundAlert,
              onChanged: (value) async {
                try {
                  await controller.setForegroundAlert(value);
                } catch (error) {
                  await onError(error);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              try {
                await controller.initialize();
              } catch (error) {
                await onError(error);
              }
            },
            icon: const Icon(Icons.power_settings_new_outlined),
            label: const Text('Initialize Client'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              try {
                await controller.requestChannel();
              } catch (error) {
                await onError(error);
              }
            },
            icon: const Icon(Icons.link_outlined),
            label: const Text('Request Channel'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await controller.closeChannel();
              } catch (error) {
                await onError(error);
              }
            },
            icon: const Icon(Icons.link_off_outlined),
            label: const Text('Close Channel'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await controller.refreshInitialActivation();
              } catch (error) {
                await onError(error);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Initial Activation'),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('clear-event-logs-button'),
              onPressed: controller.clearEventLogs,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear Event Logs'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.controller,
    required this.onError,
  });

  final WnsExampleController controller;
  final Future<void> Function(Object error) onError;

  @override
  Widget build(BuildContext context) {
    final initialActivation = controller.initialActivation;

    return _SectionPanel(
      title: 'Summary',
      subtitle: 'Compact status view for the latest packaged lifecycle state.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                label: Text(
                  controller.initialized
                      ? 'Client: Initialized'
                      : 'Client: Not Initialized',
                ),
              ),
              Chip(
                label: Text(
                  initialActivation == null
                      ? 'Initial Activation: Empty'
                      : 'Initial Activation: Available',
                ),
              ),
              if (controller.channelUri != '-')
                ActionChip(
                  label: const Text('Copy Channel URI'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: controller.channelUri),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryTile(
            label: 'Channel URI',
            valueKey: const ValueKey('channel-uri-value'),
            trailing: controller.channelUri == '-'
                ? null
                : IconButton(
                    tooltip: 'Copy Channel URI',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: controller.channelUri),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                  ),
            child: _SelectablePreviewText(controller.channelUri),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Channel Expiration',
            valueKey: const ValueKey('channel-expiration-value'),
            child: Text(
              controller.channelExpirationTime == null
                  ? '-'
                  : '${_formatDateTime(controller.channelExpirationTime!)} '
                        '(isExpired=${controller.channelIsExpired})',
            ),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Initial Activation Checked At',
            valueKey: const ValueKey('initial-activation-checked-at-value'),
            child: Text(
              controller.initialActivationCheckedAt == null
                  ? '-'
                  : _formatDateTime(controller.initialActivationCheckedAt!),
            ),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Initial Activation',
            valueKey: const ValueKey('initial-activation-value'),
            child: initialActivation == null
                ? const Text('No activation')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InlineMetric(
                        label: 'Type',
                        value: initialActivation.type.name,
                      ),
                      const SizedBox(height: 8),
                      _InlineMetric(
                        label: 'Kind',
                        value: initialActivation.kind.name,
                      ),
                      const SizedBox(height: 8),
                      _SelectablePreviewText(
                        initialActivation.payload.launchArguments ?? '',
                      ),
                      const SizedBox(height: 8),
                      _InlineMetric(
                        label: 'Data',
                        value: _formatMap(initialActivation.payload.data),
                      ),
                      if (initialActivation.userInput.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InlineMetric(
                          label: 'User Input',
                          value: _formatMap(initialActivation.userInput),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTimelineSection extends StatelessWidget {
  const _EventTimelineSection({required this.entries});

  final List<WnsEventLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: 'Event Timeline',
      subtitle:
          'Foreground and opened-app events are appended here in newest-first order.',
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No lifecycle events yet. Send a toast or click a notification to populate the list.',
                key: ValueKey('empty-timeline-message'),
              ),
            )
          : Column(
              children: List<Widget>.generate(
                entries.length,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 12),
                  child: _EventLogTile(
                    key: ValueKey('timeline-entry-$index'),
                    entry: entries[index],
                  ),
                ),
              ),
            ),
    );
  }
}

class _EventLogTile extends StatelessWidget {
  const _EventLogTile({
    super.key,
    required this.entry,
  });

  final WnsEventLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = switch (entry.source) {
      WnsEventLogSource.foregroundMessage => colorScheme.primary,
      WnsEventLogSource.openedApp => colorScheme.tertiary,
    };
    final sourceLabel = switch (entry.source) {
      WnsEventLogSource.foregroundMessage => 'Foreground',
      WnsEventLogSource.openedApp => 'Opened App',
    };
    final primaryLabel = entry.sourceTimestamp == null
        ? 'Logged At: ${_formatDateTime(entry.loggedAt)}'
        : 'Received At: ${_formatDateTime(entry.sourceTimestamp!)}';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(label: Text(sourceLabel)),
                        Chip(label: Text(entry.notificationType.name)),
                        if (entry.messageSource != null)
                          Chip(label: Text(entry.messageSource!.name)),
                        if (entry.activationKind != null)
                          Chip(label: Text(entry.activationKind!.name)),
                        Text(
                          primaryLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (entry.sourceTimestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Logged At: ${_formatDateTime(entry.loggedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InlineMetric(
                      label: 'Arguments',
                      value: _dashIfEmpty(entry.arguments),
                    ),
                    const SizedBox(height: 8),
                    _InlineMetric(
                      label: 'Data',
                      value: _formatMap(entry.data),
                    ),
                    if (entry.userInput.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InlineMetric(
                        label: 'User Input',
                        value: _formatMap(entry.userInput),
                      ),
                    ],
                    if (entry.rawPayload != null &&
                        entry.rawPayload!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: const Text('Payload Details'),
                        subtitle: Text(_truncate(entry.rawPayload!, 120)),
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _formatPayload(entry.rawPayload!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Consolas',
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.child,
    this.valueKey,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Key? valueKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...?(trailing == null ? null : <Widget>[trailing!]),
            ],
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: valueKey,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SelectablePreviewText extends StatelessWidget {
  const _SelectablePreviewText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SelectionArea(
        child: Text(
          _dashIfEmpty(value),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.45,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

String _formatMap(Map<String, String> data) {
  if (data.isEmpty) {
    return '{}';
  }

  return data.entries.map((entry) => '${entry.key}=${entry.value}').join(', ');
}

String _formatPayload(String payload) {
  return payload.trim().isEmpty ? '-' : payload.trim();
}

String _dashIfEmpty(String value) {
  return value.trim().isEmpty ? '-' : value;
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength - 3)}...';
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  final year = value.year.toString().padLeft(4, '0');
  final month = twoDigits(value.month);
  final day = twoDigits(value.day);
  final hour = twoDigits(value.hour);
  final minute = twoDigits(value.minute);
  final second = twoDigits(value.second);

  return '$year-$month-$day $hour:$minute:$second';
}
