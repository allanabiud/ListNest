import 'package:flutter/material.dart';

import '../models/list.dart';
import 'list_detail_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({
    super.key,
    required this.archivedLists,
    required this.useGridView,
    required this.onUnarchiveLists,
    required this.onDeleteLists,
    required this.onArchiveUpdated,
  });

  final List<AppList> archivedLists;
  final bool useGridView;
  final ValueChanged<List<AppList>> onUnarchiveLists;
  final ValueChanged<List<AppList>> onDeleteLists;
  final VoidCallback onArchiveUpdated;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final Set<AppList> _selectedLists = {};
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();
  final Map<AppList, int> _originalOrder = {};

  bool get _isSelectionMode => _selectedLists.isNotEmpty;
  int get _selectedCount => _selectedLists.length;
  bool get _areAllSelectedPinned =>
      _selectedLists.isNotEmpty && _selectedLists.every((list) => list.isPinned);

  @override
  void initState() {
    super.initState();
    _captureOriginalOrder();
    _sortArchivedLists();
  }

  @override
  void didUpdateWidget(covariant ArchivePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _captureOriginalOrder();
    _sortArchivedLists();
  }

  void _toggleListSelection(AppList list) {
    setState(() {
      if (_selectedLists.contains(list)) {
        _selectedLists.remove(list);
      } else {
        _selectedLists.add(list);
      }
    });
  }

  void _clearSelection() {
    if (_selectedLists.isEmpty) {
      return;
    }
    setState(() {
      _selectedLists.clear();
    });
  }

  void _deleteSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final indices = _selectedLists
        .map(widget.archivedLists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final lists = <AppList>[];
    setState(() {
      _selectedLists.clear();
    });

    for (final index in indices) {
      final removedList = widget.archivedLists.removeAt(index);
      lists.insert(0, removedList);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedArchivedCard(
          context,
          removedList,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    widget.onDeleteLists(lists);
  }

  void _unarchiveSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final indices = _selectedLists
        .map(widget.archivedLists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final lists = <AppList>[];
    setState(() {
      _selectedLists.clear();
    });

    for (final index in indices) {
      final removedList = widget.archivedLists.removeAt(index);
      lists.insert(0, removedList);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedArchivedCard(
          context,
          removedList,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    widget.onUnarchiveLists(lists);
  }

  void _togglePinSelectedLists() {
    if (_selectedLists.isEmpty) {
      return;
    }
    final shouldPin = !_areAllSelectedPinned;
    final selected = _selectedLists.toList();
    final removalIndices = selected
        .map(widget.archivedLists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _selectedLists.clear();
    });

    final removedItems = <AppList>[];
    for (final index in removalIndices) {
      final removed = widget.archivedLists.removeAt(index);
      removedItems.add(removed);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedArchivedCard(
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
    widget.archivedLists.addAll(removedItems);
    _sortArchivedLists();

    final insertionIndices = removedItems
        .map(widget.archivedLists.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort();
    for (final index in insertionIndices) {
      _listKey.currentState?.insertItem(
        index,
        duration: const Duration(milliseconds: 200),
      );
    }
    widget.onArchiveUpdated();
  }

  void _sortArchivedLists() {
    widget.archivedLists.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final indexA = _originalOrder[a] ?? 0;
      final indexB = _originalOrder[b] ?? 0;
      return indexA.compareTo(indexB);
    });
  }

  void _captureOriginalOrder() {
    for (var i = 0; i < widget.archivedLists.length; i++) {
      _originalOrder.putIfAbsent(widget.archivedLists[i], () => i);
    }
  }

  Widget _buildArchivedCard(
    BuildContext context,
    AppList list,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final archivedAt = list.archivedAt ?? list.createdAt;
    const isCompact = true;
    final contentPadding = EdgeInsets.all(isCompact ? 12 : 16);
    final metaSpacing = isCompact ? 4.0 : 6.0;
    final timestampSpacing = isCompact ? 6.0 : 8.0;

    return AnimatedScale(
      scale: isSelected ? 0.98 : 1.0,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListDetailPage(list: list),
                      ),
                    );
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
                          'Archived ${_formatDateTime(archivedAt)}',
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

  Widget _buildAnimatedArchivedCard(
    BuildContext context,
    AppList list,
    bool isSelected,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: _buildArchivedCard(context, list, isSelected),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 24,
    );
    final titleText = _isSelectionMode
        ? '${_selectedCount == 1 ? '1 list' : '$_selectedCount lists'} selected'
        : 'Archive';
    const isCompact = true;
    final listPadding = EdgeInsets.all(isCompact ? 12 : 16);
    final itemGap = isCompact ? 6.0 : 10.0;
    final gridSpacing = isCompact ? 10.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(titleText, style: titleStyle),
        leading: _isSelectionMode
            ? AnimatedSwitcher(
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
                child: IconButton(
                  key: const ValueKey<String>('close'),
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
              )
            : null,
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
        child: _isSelectionMode
            ? Column(
                key: const ValueKey<String>('archiveSelectionFab'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'pinArchivedListsFab',
                    onPressed: _togglePinSelectedLists,
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    child: Icon(
                      _areAllSelectedPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'unarchiveListsFab',
                    onPressed: _unarchiveSelectedLists,
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    child: const Icon(Icons.unarchive_outlined),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'deleteArchivedListsFab',
                    onPressed: _deleteSelectedLists,
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    child: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : const SizedBox.shrink(key: ValueKey<String>('noFab')),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: widget.useGridView
                ? GridView.builder(
                    padding: listPadding,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: gridSpacing,
                      crossAxisSpacing: gridSpacing,
                      childAspectRatio: isCompact ? 1.6 : 1.4,
                    ),
                    itemCount: widget.archivedLists.length,
                    itemBuilder: (context, index) {
                      final list = widget.archivedLists[index];
                      final isSelected = _selectedLists.contains(list);
                      return _buildArchivedCard(context, list, isSelected);
                    },
                  )
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: widget.archivedLists.length,
                    padding: listPadding,
                    itemBuilder: (context, index, animation) {
                      final list = widget.archivedLists[index];
                      final isSelected = _selectedLists.contains(list);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAnimatedArchivedCard(
                            context,
                            list,
                            isSelected,
                            animation,
                          ),
                          if (index != widget.archivedLists.length - 1)
                            SizedBox(height: itemGap),
                        ],
                      );
                    },
                  ),
          ),
          if (widget.archivedLists.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No archived lists',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Archive lists to find them here',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
