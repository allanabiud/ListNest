import 'package:flutter/material.dart';

import '../models/list.dart';
import 'list_detail_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({
    super.key,
    required this.title,
    required this.lists,
    required this.useGridView,
    required this.onOpenSettings,
    required this.onOpenArchive,
    required this.onListUpdated,
    required this.onSelectionChanged,
    required this.onArchiveLists,
  });

  final String title;
  final List<AppList> lists;
  final bool useGridView;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenArchive;
  final VoidCallback onListUpdated;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<List<AppList>> onArchiveLists;

  @override
  State<ListPage> createState() => ListPageState();
}

class ListPageState extends State<ListPage> {
  final Set<AppList> _selectedLists = {};
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  final Map<AppList, int> _originalOrder = {};

  bool get _isSelectionMode => _selectedLists.isNotEmpty;
  int get _selectedCount => _selectedLists.length;
  bool get _areAllSelectedPinned =>
      _selectedLists.isNotEmpty && _selectedLists.every((list) => list.isPinned);

  @override
  void initState() {
    super.initState();
    _captureOriginalOrder();
    _sortLists();
  }

  @override
  void didUpdateWidget(covariant ListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _captureOriginalOrder();
    _sortLists();
  }

  void _toggleListSelection(AppList list) {
    setState(() {
      if (_selectedLists.contains(list)) {
        _selectedLists.remove(list);
      } else {
        _selectedLists.add(list);
      }
    });
    widget.onSelectionChanged(_isSelectionMode);
  }

  void _selectAllLists() {
    setState(() {
      _selectedLists
        ..clear()
        ..addAll(widget.lists);
    });
    widget.onSelectionChanged(_isSelectionMode);
  }

  void insertList(int index) {
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 200),
    );
  }

  void togglePinSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final shouldPin = !_areAllSelectedPinned;
    final selected = _selectedLists.toList();
    final removalIndices = selected
        .map(widget.lists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _selectedLists.clear();
    });

    final removedItems = <AppList>[];
    for (final index in removalIndices) {
      final removed = widget.lists.removeAt(index);
      removedItems.add(removed);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedListCard(
          context,
          removed,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    _captureOriginalOrder();
    for (final list in removedItems) {
      list.isPinned = shouldPin;
    }
    widget.lists.addAll(removedItems);
    _sortLists();

    final insertionIndices = removedItems
        .map(widget.lists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort();
    for (final index in insertionIndices) {
      _listKey.currentState?.insertItem(
        index,
        duration: const Duration(milliseconds: 200),
      );
    }
    widget.onListUpdated();
    widget.onSelectionChanged(false);
  }

  void resortLists() {
    setState(() {
      _sortLists();
    });
  }

  void _sortLists() {
    widget.lists.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final indexA = _originalOrder[a] ?? 0;
      final indexB = _originalOrder[b] ?? 0;
      return indexA.compareTo(indexB);
    });
  }

  void _captureOriginalOrder() {
    for (var i = 0; i < widget.lists.length; i++) {
      _originalOrder.putIfAbsent(widget.lists[i], () => i);
    }
  }

  bool get areAllSelectedPinned => _areAllSelectedPinned;

  void clearSelection() {
    if (_selectedLists.isEmpty) {
      return;
    }
    setState(() {
      _selectedLists.clear();
    });
    widget.onSelectionChanged(false);
  }

  void deleteSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final indices = _selectedLists
        .map(widget.lists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _selectedLists.clear();
    });

    for (final index in indices) {
      final removedList = widget.lists.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedListCard(
          context,
          removedList,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }
    widget.onListUpdated();
    widget.onSelectionChanged(false);
  }

  void archiveSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final indices = _selectedLists
        .map(widget.lists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final archived = <AppList>[];
    setState(() {
      _selectedLists.clear();
    });

    for (final index in indices) {
      final removedList = widget.lists.removeAt(index);
      removedList.archivedAt = DateTime.now();
      archived.insert(0, removedList);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedListCard(
          context,
          removedList,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    widget.onArchiveLists(archived);
    widget.onListUpdated();
    widget.onSelectionChanged(false);
  }

  Widget _buildListCard(
    BuildContext context,
    AppList list,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const isCompact = true;
    final contentPadding = EdgeInsets.all(isCompact ? 12 : 16);
    final metaSpacing = isCompact ? 4.0 : 6.0;
    final timestampSpacing = isCompact ? 6.0 : 8.0;

    return AnimatedScale(
      scale: isSelected ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                color: colorScheme.secondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onLongPress: () {
                    _toggleListSelection(list);
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleListSelection(list);
                      return;
                    }
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => ListDetailPage(list: list),
                          ),
                        )
                        .then((_) => widget.onListUpdated());
                  },
                  child: Padding(
                    padding: contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCompact)
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        list.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (list.isPinned) ...[
                                      const SizedBox(width: 8),
                                      _buildPinnedBadge(
                                        context,
                                        textTheme,
                                        colorScheme,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${list.items.length}',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  list.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (list.isPinned) ...[
                                const SizedBox(width: 8),
                                _buildPinnedBadge(
                                  context,
                                  textTheme,
                                  colorScheme,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: metaSpacing),
                          Text(
                            '${list.items.length} items',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.85),
                            ),
                          ),
                        ],
                        SizedBox(height: timestampSpacing),
                        Text(
                          'Created ${_formatDateTime(list.createdAt)}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedListCard(
    BuildContext context,
    AppList list,
    bool isSelected,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: _buildListCard(context, list, isSelected),
      ),
    );
  }

  Widget _buildPinnedBadge(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Badge(
      backgroundColor: colorScheme.tertiaryContainer,
      label: Text(
        'PINNED',
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onTertiaryContainer,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    final day = value.day;
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24);
    final titleText = _isSelectionMode
        ? '${_selectedCount == 1 ? '1 list' : '$_selectedCount lists'} selected'
        : widget.title;
    const isCompact = true;
    final listPadding = EdgeInsets.all(isCompact ? 12 : 16);
    final itemGap = isCompact ? 6.0 : 10.0;
    final gridSpacing = isCompact ? 10.0 : 14.0;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          centerTitle: true,
          title: Text(titleText, style: appBarTitleStyle),
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
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
            child: _isSelectionMode
                ? IconButton(
                    key: const ValueKey<String>('close'),
                    icon: const Icon(Icons.close),
                    onPressed: clearSelection,
                  )
                : IconButton(
                    key: const ValueKey<String>('archive'),
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: widget.onOpenArchive,
                  ),
          ),
          actions: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
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
              child: _isSelectionMode
                  ? IconButton(
                      key: const ValueKey<String>('selectAll'),
                      icon: const Icon(Icons.select_all),
                      onPressed: _selectAllLists,
                    )
                  : IconButton(
                      key: const ValueKey<String>('settings'),
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: widget.onOpenSettings,
                    ),
            ),
          ],
        ),
        if (!widget.useGridView)
          SliverPadding(
            padding: listPadding,
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: widget.lists.length,
              itemBuilder: (context, index, animation) {
                final list = widget.lists[index];
                final isLast = index == widget.lists.length - 1;
                final isSelected = _selectedLists.contains(list);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedListCard(
                      context,
                      list,
                      isSelected,
                      animation,
                    ),
                    if (!isLast) SizedBox(height: itemGap),
                  ],
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: listPadding,
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = widget.lists[index];
                  final isSelected = _selectedLists.contains(list);
                  return _buildListCard(context, list, isSelected);
                },
                childCount: widget.lists.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                childAspectRatio: isCompact ? 1.6 : 1.4,
              ),
            ),
          ),
        if (widget.lists.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No lists yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create one to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
