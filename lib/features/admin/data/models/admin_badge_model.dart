class AdminBadgeModel {
  final String slug;
  final String name;
  final String description;
  final String? iconUrl;
  final String type;

  AdminBadgeModel({
    required this.slug,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.type,
  });

  factory AdminBadgeModel.fromJson(Map<String, dynamic> json) {
    return AdminBadgeModel(
      slug: json['slug'],
      name: json['name'],
      description: json['description'] ?? '',
      iconUrl: json['icon_url'],
      type: json['type'] ?? 'league',
    );
  }
}