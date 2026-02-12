import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/list.dart';
import 'pages/archive_page.dart';
import 'pages/settings_page.dart';
import 'pages/list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AppListAdapter());
  Hive.registerAdapter(AppListItemAdapter());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useAmoledDark = false;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _openSettingsBox().then((_) => _loadAppearancePrefs());
  }

  Future<void> _openSettingsBox() async {
    _settingsBox = await Hive.openBox('settings');
  }

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveThemeMode(mode);
  }

  void _updateAmoledMode(bool value) {
    setState(() {
      _useAmoledDark = value;
    });
    _saveAmoledMode(value);
  }

  Future<void> _loadAppearancePrefs() async {
    final storedTheme = _settingsBox.get('theme_mode');
    final storedAmoled = _settingsBox.get('use_amoled_dark');
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = _themeModeFromIndex(storedTheme);
      _useAmoledDark = storedAmoled ?? false;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    await _settingsBox.put('theme_mode', _themeModeToIndex(mode));
  }

  Future<void> _saveAmoledMode(bool value) async {
    await _settingsBox.put('use_amoled_dark', value);
  }

  ThemeMode _themeModeFromIndex(int? value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      case 0:
      default:
        return ThemeMode.system;
    }
  }

  int _themeModeToIndex(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: const FadeUpwardsPageTransitionsBuilder(),
      },
    );
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        );
        ColorScheme darkColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        );

        final lightScheme = lightDynamic?.harmonized() ?? lightColorScheme;
        final darkScheme = darkDynamic?.harmonized() ?? darkColorScheme;

        final amoledDarkScheme = darkScheme.copyWith(surface: Colors.black);

        return MaterialApp(
          title: 'ListNest',
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true, // Explicitly enable M3
            fontFamily: "Rubik",
            pageTransitionsTheme: pageTransitionsTheme,
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightScheme.surface,
              indicatorColor: lightScheme.secondaryContainer,
              elevation: 1,
              height: 70,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final base = ThemeData.light().textTheme.labelMedium;
                if (states.contains(WidgetState.selected)) {
                  return base?.copyWith(fontWeight: FontWeight.w600);
                }
                return base;
              }),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: _useAmoledDark ? amoledDarkScheme : darkScheme,
            useMaterial3: true,
            fontFamily: "Rubik",
            pageTransitionsTheme: pageTransitionsTheme,
            scaffoldBackgroundColor: _useAmoledDark ? Colors.black : null,
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: _useAmoledDark
                  ? Colors.black
                  : darkScheme.surface,
              indicatorColor: darkScheme.secondaryContainer,
              elevation: 1,
              height: 70,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final base = ThemeData.dark().textTheme.labelMedium;
                if (states.contains(WidgetState.selected)) {
                  return base?.copyWith(fontWeight: FontWeight.w600);
                }
                return base;
              }),
            ),
          ),
          themeMode: _themeMode,
          home: MyHomePage(
            title: 'ListNest',
            themeMode: _themeMode,
            onThemeModeChanged: _updateThemeMode,
            useAmoledDark: _useAmoledDark,
            onAmoledModeChanged: _updateAmoledMode,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.useAmoledDark,
    required this.onAmoledModeChanged,
  });

  final String title;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool useAmoledDark;
  final ValueChanged<bool> onAmoledModeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<AppList> _activeLists = [];
  final List<AppList> _archivedLists = [];
  final TextEditingController _textFieldController = TextEditingController();
  final GlobalKey<ListPageState> _listPageKey = GlobalKey<ListPageState>();
  bool _isListSelectionMode = false;
  bool _useGridView = false;
  late Box<bool> _layoutPrefsBox;
  late Box<AppList> _listBox;
  static const String _listsBoxName = 'lists';

  @override
  void initState() {
    super.initState();
    _openHiveBoxes().then((_) {
      _loadLayoutPrefs();
      _loadListPrefs();
    });
  }

  Future<void> _openHiveBoxes() async {
    _layoutPrefsBox = await Hive.openBox<bool>('layout_prefs');
    _listBox = await Hive.openBox<AppList>(_listsBoxName);
  }

  Future<void> _loadLayoutPrefs() async {
    final storedGrid = _layoutPrefsBox.get('use_grid_view');
    if (!mounted) {
      return;
    }
    setState(() {
      _useGridView = storedGrid ?? false;
    });
  }

  Future<void> _saveGridView(bool value) async {
    await _layoutPrefsBox.put('use_grid_view', value);
  }

  Future<void> _loadListPrefs() async {
    _activeLists.clear();
    _archivedLists.clear();

    for (var i = 0; i < _listBox.length; i++) {
      final list = _listBox.getAt(i);
      if (list != null) {
        if (list.archivedAt == null) {
          _activeLists.add(list);
        } else {
          _archivedLists.add(list);
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {});
    _listPageKey.currentState?.resortLists();
  }

  Future<void> _persistLists() async {
    final Map<String, AppList> allLists = {};
    for (final list in _activeLists) {
      allLists[list.id] = list;
    }
    for (final list in _archivedLists) {
      allLists[list.id] = list;
    }

    await _listBox.clear();
    for (final listId in allLists.keys) {
      await _listBox.put(listId, allLists[listId]!);
    }
  }

  void _displayDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add list',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          title: const Text('Add a List'),
          content: TextField(
            controller: _textFieldController,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'List name',
              hintText: 'Type list name',
              prefixIcon: Icon(Icons.list_alt_outlined),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _textFieldController.clear();
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Add'),
              onPressed: () {
                final name = _textFieldController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                setState(() {
                  _activeLists.add(
                    AppList(name: name, createdAt: DateTime.now()),
                  );
                  _textFieldController.clear();
                });
                _persistLists();
                _listPageKey.currentState?.insertList(_activeLists.length - 1);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListPage(
        key: _listPageKey,
        title: widget.title,
        lists: _activeLists,
        useGridView: _useGridView,
        onOpenSettings: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SettingsPage(
                title: 'Settings',
                themeMode: widget.themeMode,
                onThemeModeChanged: widget.onThemeModeChanged,
                useAmoledDark: widget.useAmoledDark,
                onAmoledModeChanged: widget.onAmoledModeChanged,
                useGridView: _useGridView,
                onListDisplayChanged: (value) {
                  setState(() {
                    _useGridView = value;
                  });
                  _saveGridView(value);
                },
              ),
            ),
          );
        },
        onOpenArchive: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArchivePage(
                archivedLists: _archivedLists,
                useGridView: _useGridView,
                onUnarchiveLists: (lists) {
                  setState(() {
                    _archivedLists.removeWhere(lists.contains);
                    final startIndex = _activeLists.length;
                    for (final list in lists) {
                      list.archivedAt = null;
                    }
                    _activeLists.addAll(lists);
                    for (var i = 0; i < lists.length; i++) {
                      _listPageKey.currentState?.insertList(startIndex + i);
                    }
                    _listPageKey.currentState?.resortLists();
                  });
                  _persistLists();
                },
                onDeleteLists: (lists) {
                  setState(() {
                    _archivedLists.removeWhere(lists.contains);
                  });
                  _persistLists();
                },
                onArchiveUpdated: _persistLists,
              ),
            ),
          );
        },
        onListUpdated: () {
          setState(() {});
          _persistLists();
        },
        onSelectionChanged: (isSelectionMode) {
          setState(() {
            _isListSelectionMode = isSelectionMode;
          });
        },
        onArchiveLists: (lists) {
          setState(() {
            _archivedLists.addAll(lists);
          });
          _persistLists();
        },
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: curved, child: child),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.bottomRight,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: _isListSelectionMode
            ? Column(
                key: const ValueKey<String>('selectionFab'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'pinListsFab',
                    onPressed: () {
                      _listPageKey.currentState?.togglePinSelectedLists();
                    },
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    child: Icon(
                      _listPageKey.currentState?.areAllSelectedPinned ?? false
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'archiveListsFab',
                    onPressed: () {
                      _listPageKey.currentState?.archiveSelectedLists();
                    },
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    child: const Icon(Icons.archive_outlined),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'deleteListsFab',
                    onPressed: () {
                      _listPageKey.currentState?.deleteSelectedLists();
                    },
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    child: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : FloatingActionButton(
                key: const ValueKey<String>('addFab'),
                onPressed: _displayDialog,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
