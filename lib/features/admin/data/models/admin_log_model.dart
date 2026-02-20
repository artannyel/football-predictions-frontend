class AdminLogModel {
  final String filename;
  final String size;
  final String lastModified;

  AdminLogModel({
    required this.filename,
    required this.size,
    required this.lastModified,
  });

  factory AdminLogModel.fromJson(Map<String, dynamic> json) {
    return AdminLogModel(
      filename: json['name'],
      size: json['size'],
      lastModified: json['updated_at'],
    );
  }
}