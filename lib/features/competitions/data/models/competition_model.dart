class CompetitionModel {
  final int id;
  final String name;
  final String code;
  final String type;
  final String? emblem;
  final String areaName;

  CompetitionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.emblem,
    required this.areaName,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      type: json['type'],
      emblem: json['emblem'],
      // Acessando o nome da área dentro do objeto aninhado 'area'
      areaName: json['area'] != null ? json['area']['name'] : '',
    );
  }
}