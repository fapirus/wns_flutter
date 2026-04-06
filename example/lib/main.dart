import 'package:flutter/material.dart';

import 'package:wns_flutter_example/app_theme.dart';
import 'package:wns_flutter_example/notification_setting_card.dart';
import 'package:wns_flutter_example/windows_notification_service_card.dart';
import 'package:wns_flutter_example/wns_demo_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(client: DefaultWnsDemoClient()));
}

@immutable
class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.client});

  final WnsDemoClient client;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Windows Notification Service'),
          actions: [
            PopupMenuButton<ThemeMode>(
              key: const ValueKey('theme-mode-menu'),
              tooltip: 'Theme mode',
              icon: const Icon(Icons.palette_outlined),
              initialValue: _themeMode,
              onSelected: (mode) {
                setState(() {
                  _themeMode = mode;
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: ListView(
                    key: ValueKey(isDesktop ? 'desktop-shell' : 'mobile-shell'),
                    padding: const EdgeInsets.all(20),
                    children: [
                      _HeroHeader(themeMode: _themeMode),
                      const SizedBox(height: 20),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 340,
                              child: NotificationSettingCard(client: widget.client),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: WindowsNotificationServiceCard(
                                client: widget.client,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        NotificationSettingCard(client: widget.client),
                        const SizedBox(height: 16),
                        WindowsNotificationServiceCard(client: widget.client),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desktop-style WNS validation console',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspect channel setup, initial activation, foreground delivery, and opened-app activation in a single responsive sample.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HeaderBadge(
                      icon: Icons.notifications_active_outlined,
                      label: 'Toast Lifecycle Demo',
                    ),
                    _HeaderBadge(
                      icon: Icons.inventory_2_outlined,
                      label: 'Packaged MSIX Only',
                    ),
                    _HeaderBadge(
                      icon: Icons.palette_outlined,
                      label: switch (themeMode) {
                        ThemeMode.system => 'Theme: System',
                        ThemeMode.light => 'Theme: Light',
                        ThemeMode.dark => 'Theme: Dark',
                      },
                    ),
                  ],
                ),
              ],
            );

            if (!isWide) {
              return content;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: content),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Use the right-side timeline to compare streamed foreground events with activation events. This layout is optimized for desktop-width validation sessions.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
