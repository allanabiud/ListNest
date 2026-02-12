class AppList {
  AppList({
    required this.name,
    required this.createdAt,
    this.archivedAt,
    this.isPinned = false,
    List<AppListItem>? items,
  }) : items = items ?? [];

  final String name;
  final DateTime createdAt;
  DateTime? archivedAt;
  bool isPinned;
  final List<AppListItem> items;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'isPinned': isPinned,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory AppList.fromJson(Map<String, dynamic> json) {
    return AppList(
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => AppListItem.fromJson(item))
          .toList(),
    );
  }
}

class AppListItem {
  AppListItem({required this.name, this.isChecked = false});

  final String name;
  bool isChecked;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isChecked': isChecked,
    };
  }

  factory AppListItem.fromJson(Map<String, dynamic> json) {
    return AppListItem(
      name: json['name'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }
}
