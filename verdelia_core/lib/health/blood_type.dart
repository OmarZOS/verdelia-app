class BloodType {
  final int id_blood_type;
  final String blood_type_desc;
  BloodType({required this.id_blood_type, required this.blood_type_desc});

  factory BloodType.fromJson(Map<String, dynamic> json) {
    return BloodType(
        id_blood_type: json['id_blood_type'] ?? 0,
        blood_type_desc: json['blood_type_desc'] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      'id_blood_type': id_blood_type,
      'blood_type_desc': blood_type_desc,
    };
  }
}
