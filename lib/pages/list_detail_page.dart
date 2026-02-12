import 'package:flutter/material.dart';

import '../models/list.dart';

class ListDetailPage extends StatefulWidget {
  const ListDetailPage({super.key, required this.list});

  final AppList list;

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  final TextEditingController _itemController = TextEditingController();
  final Set<AppListItem> _selectedItems = {};
  final GlobalKey<AnimatedListState> _itemsKey =
      GlobalKey<AnimatedListState>();

  bool get _isSelectionMode => _selectedItems.isNotEmpty;
  int get _selectedCount => _selectedItems.length;

  void _toggleItemSelection(AppListItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _selectAllItems() {
    setState(() {
      _selectedItems
        ..clear()
        ..addAll(widget.list.items);
    });
  }

  void _clearSelection() {
    if (_selectedItems.isEmpty) {
      return;
    }
    setState(() {
      _selectedItems.clear();
    });
  }

  void _deleteSelectedItems() {
    if (_selectedItems.isEmpty) {
      return;
    }
    final indices = _selectedItems
        .map(widget.list.items.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _selectedItems.clear();
    });

    for (final index in indices) {
      final removedItem = widget.list.items.removeAt(index);
      _itemsKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedItemTile(
          context,
          removedItem,
          false,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add item',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          title: const Text('Add item'),
          content: TextField(
            controller: _itemController,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'Type item name',
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
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _itemController.clear();
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Add'),
              onPressed: () {
                final name = _itemController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                setState(() {
                  widget.list.items.add(AppListItem(name: name));
                  _itemController.clear();
                });
                _itemsKey.currentState?.insertItem(
                  widget.list.items.length - 1,
                  duration: const Duration(milliseconds: 200),
                );
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
    final textTheme = Theme.of(context).textTheme;
    final titleText = _isSelectionMode
      ? '${_selectedCount == 1 ? '1 item' : '$_selectedCount items'} selected'
      : widget.list.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleText,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
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
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllItems,
            ),
          ],
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
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
            ? FloatingActionButton(
                key: const ValueKey<String>('deleteFab'),
                onPressed: _deleteSelectedItems,
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                child: const Icon(Icons.delete_outline),
              )
            : FloatingActionButton(
                key: const ValueKey<String>('addFab'),
                onPressed: _showAddItemDialog,
                child: const Icon(Icons.add),
              ),
      ),
      body: Stack(
        children: [
          AnimatedList(
            key: _itemsKey,
            initialItemCount: widget.list.items.length,
            itemBuilder: (context, index, animation) {
              final item = widget.list.items[index];
              final isSelected = _selectedItems.contains(item);
              return _buildAnimatedItemTile(
                context,
                item,
                isSelected,
                animation,
              );
            },
          ),
          if (widget.list.items.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.list_alt_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No items yet',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add items to start your list',
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

  Widget _buildItemTile(
    BuildContext context,
    AppListItem item,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedScale(
      scale: isSelected ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onLongPress: () {
                _toggleItemSelection(item);
              },
              onTap: _isSelectionMode
                  ? () {
                      _toggleItemSelection(item);
                    }
                  : null,
              child: ListTile(
                leading: Checkbox(
                  value: item.isChecked,
                  onChanged: (value) {
                    setState(() {
                      item.isChecked = value ?? false;
                    });
                  },
                ),
                title: Text(
                  item.name,
                  style: textTheme.bodyLarge?.copyWith(
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isChecked
                        ? colorScheme.onSurface.withOpacity(0.55)
                        : colorScheme.onSurface,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 10,
              right: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItemTile(
    BuildContext context,
    AppListItem item,
    bool isSelected,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: _buildItemTile(context, item, isSelected),
      ),
    );
  }
}
