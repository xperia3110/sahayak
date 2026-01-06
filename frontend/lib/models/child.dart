class Child {
  final int? id;
  final String nickname;
  final int ageInMonths;

  Child({
    this.id,
    required this.nickname,
    required this.ageInMonths,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      nickname: json['nickname'],
      ageInMonths: json['age_in_months'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'age_in_months': ageInMonths,
    };
  }
}
