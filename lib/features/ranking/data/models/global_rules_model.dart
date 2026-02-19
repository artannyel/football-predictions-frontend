class GlobalRulesModel {
  final String title;
  final String description;
  final List<GlobalRuleItem> rules;

  GlobalRulesModel({
    required this.title,
    required this.description,
    required this.rules,
  });

  factory GlobalRulesModel.fromJson(Map<String, dynamic> json) {
    final global = json['global_ranking'] ?? {};
    return GlobalRulesModel(
      title: global['title'] ?? 'Ranking Global',
      description: global['description'] ?? '',
      rules: (global['rules'] as List?)
              ?.map((e) => GlobalRuleItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GlobalRuleItem {
  final String title;
  final String description;

  GlobalRuleItem({required this.title, required this.description});

  factory GlobalRuleItem.fromJson(Map<String, dynamic> json) {
    return GlobalRuleItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}