class BadgeModel {
  final String slug;
  final int count;
  final String name;
  final String description;
  final String? iconUrl;

  BadgeModel({
    required this.slug,
    required this.count,
    required this.name,
    required this.description,
    this.iconUrl,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      slug: json['slug'] ?? '',
      count: json['count'] ?? 1,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'],
    );
  }
}

class UserModel {
  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final List<BadgeModel> badges;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.badges = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      badges: json['badges'] != null
          ? (json['badges'] as List)
              .map((e) => BadgeModel.fromJson(e))
              .toList()
          : [],
    );
  }
}

class RadarModel {
  final double precision;
  final double technique;
  final double safety;

  RadarModel({
    required this.precision,
    required this.technique,
    required this.safety,
  });

  factory RadarModel.fromJson(Map<String, dynamic> json) {
    return RadarModel(
      precision: json['precision'] ?? 0,
      technique: json['technique'] ?? 0,
      safety: json['safety'] ?? 0,
    );
  }
}

class CareerModel {
  final int totalPoints;
  final int totalPredictions;
  final double averagePoints;
  final double winRate;
  final RadarModel radar;
  final List<String> recentForm;

  CareerModel({
    required this.totalPoints,
    required this.totalPredictions,
    required this.averagePoints,
    required this.winRate,
    required this.radar,
    required this.recentForm,
  });

  factory CareerModel.fromJson(Map<String, dynamic> json) {
    return CareerModel(
      totalPoints: json['total_points'] ?? 0,
      totalPredictions: json['total_predictions'] ?? 0,
      averagePoints: (json['average_points'] ?? 0).toDouble(),
      winRate: (json['win_rate'] ?? 0).toDouble(),
      radar: RadarModel.fromJson(json['radar'] ?? {}),
      recentForm: List<String>.from(json['recent_form'] ?? []),
    );
  }
}

class HallOfFameModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String competitionName;
  final int position;
  final String year;

  HallOfFameModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.competitionName,
    required this.position,
    required this.year,
  });

  factory HallOfFameModel.fromJson(Map<String, dynamic> json) {
    return HallOfFameModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      competitionName: json['competition_name'] ?? '',
      position: json['position'] is int ? json['position'] : int.tryParse(json['position'].toString()) ?? 0,
      year: json['year'].toString(),
    );
  }
}

class UserProfileModel {
  final UserModel user;
  final CareerModel career;
  final List<HallOfFameModel> hallOfFame;

  UserProfileModel({
    required this.user,
    required this.career,
    required this.hallOfFame,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UserProfileModel(
      user: UserModel.fromJson(data),
      career: CareerModel.fromJson(data['career'] ?? {}),
      hallOfFame: (data['hall_of_fame'] as List?)
              ?.map((e) => HallOfFameModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
