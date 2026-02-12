import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'list.g.dart';

@HiveType(typeId: 0)
class AppList {
  AppList({
    String? id,
    required this.name,
    required this.createdAt,
    this.archivedAt,
    this.isPinned = false,
    List<AppListItem>? items,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  @HiveField(5)
  String id;
  @HiveField(0)
  String name;
  @HiveField(1)
  DateTime createdAt;
  @HiveField(2)
  DateTime? archivedAt;
  @HiveField(3)
  bool isPinned;
  @HiveField(4)
  List<AppListItem> items;

  // toJson and fromJson methods are no longer needed for Hive persistence
  // but keeping them for now in case they are used elsewhere.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'isPinned': isPinned,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory AppList.fromJson(Map<String, dynamic> json) {
    return AppList(
      id: json['id'] as String? ?? const Uuid().v4(),
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

@HiveType(typeId: 1)
class AppListItem {
  AppListItem({required this.name, this.isChecked = false});

  @HiveField(0)
  String name;
  @HiveField(1)
  bool isChecked;

  // toJson and fromJson methods are no longer needed for Hive persistence
  // but keeping them for now in case they are used elsewhere.
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
