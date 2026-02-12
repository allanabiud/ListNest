import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.useAmoledDark,
    required this.onAmoledModeChanged,
    required this.useGridView,
    required this.onListDisplayChanged,
  });

  final String title;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool useAmoledDark;
  final ValueChanged<bool> onAmoledModeChanged;
  final bool useGridView;
  final ValueChanged<bool> onListDisplayChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _themeMode;
  late bool _useAmoledDark;
  late bool _useGridView;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _useAmoledDark = widget.useAmoledDark;
    _useGridView = widget.useGridView;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _themeMode = widget.themeMode;
    }
    if (oldWidget.useAmoledDark != widget.useAmoledDark) {
      _useAmoledDark = widget.useAmoledDark;
    }
    if (oldWidget.useGridView != widget.useGridView) {
      _useGridView = widget.useGridView;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  setState(() {
                    _themeMode = selected;
                  });
                  widget.onThemeModeChanged(selected);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('AMOLED dark mode'),
            subtitle: const Text('Use pure black backgrounds in dark mode'),
            value: _useAmoledDark,
            onChanged: (value) {
              setState(() {
                _useAmoledDark = value;
              });
              widget.onAmoledModeChanged(value);
            },
          ),
          Divider(
            height: 24,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Layout',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('List display'),
            subtitle: Text(_useGridView ? 'Grid' : 'List'),
            value: _useGridView,
            onChanged: (value) {
              setState(() {
                _useGridView = value;
              });
              widget.onListDisplayChanged(value);
            },
          ),
          Divider(
            height: 24,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.info_outline),
            title: const Text('ListNest'),
            subtitle: const Text('A simple way to organize your lists.'),
          ),
        ],
      ),
    );
  }
}
