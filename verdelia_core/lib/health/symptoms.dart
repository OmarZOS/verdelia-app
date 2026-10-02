import 'dart:convert';
import 'dart:typed_data';

class Diagnosis {
  final int? id_diagnosis;
  final int? diagnosis_owner_id;
  final int? diagnosis_category_id;

  final int? id_diagnosis_image;
  Uint8List? diagnosis_image_data;
  final DateTime? diagnosis_created_at;
  final DateTime? diagnosis_last_updated;
  final String? diagnosis_name;
  final String? diagnosis_description;
  final String? diagnosis_instruction;
  final String? diagnosis_preparation_time;
  final String? diagnosis_category_desc;

  Diagnosis(
      {required this.id_diagnosis,
      required this.diagnosis_category_id,
      required this.id_diagnosis_image,
      required this.diagnosis_name,
      required this.diagnosis_image_data,
      required this.diagnosis_description,
      required this.diagnosis_created_at,
      required this.diagnosis_last_updated,
      required this.diagnosis_owner_id,
      required this.diagnosis_instruction,
      required this.diagnosis_preparation_time,
      required this.diagnosis_category_desc});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    Uint8List? imageData;
    int cardImageId = 0;
    if (json['diagnosis_image'] != null &&
        json['diagnosis_image'] is List &&
        json['diagnosis_image']!.isNotEmpty) {
      final imageId = json['diagnosis_image'][0]["id_diagnosis_image"];
      cardImageId = imageId;
      final imageBase64 = json['diagnosis_image'][0]["diagnosis_image_data"];
      if (imageBase64 != null && imageBase64 != "" && imageBase64 != "string") {
        imageData = base64Decode(imageBase64);
      }
    }
    return Diagnosis(
      id_diagnosis: json['id_diagnosis'] ?? 0,
      diagnosis_owner_id: json['diagnosis_owner_id'] ?? 0,
      diagnosis_category_id: json['diagnosis_category_id'] ?? 0,
      id_diagnosis_image: cardImageId,
      diagnosis_image_data: imageData,
      diagnosis_name: json['diagnosis_name'] ?? "",
      diagnosis_description: json['diagnosis_description'],
      diagnosis_instruction: json['diagnosis_instructions'],
      diagnosis_preparation_time: json['diagnosis_preparation_time'],
      diagnosis_created_at: null,
      diagnosis_last_updated: null,
      diagnosis_category_desc:
          json['diagnosis_category']['diagnosis_category_desc'] ?? "",
    );
  }
  static Uint8List? imageFromJson(List<dynamic> json) {
    Uint8List? imageData;
    if (json.isNotEmpty) {
      final imageBase64 = json[0]["diagnosis_image_data"];
      if (imageBase64 != null && imageBase64 != "" && imageBase64 != "string") {
        imageData = base64Decode(imageBase64);
      }
    }
    return imageData;
  }

  Map<String, dynamic> toJson() {
    return {
      "diagnosis": {
        "id_diagnosis": id_diagnosis ?? 0,
        "diagnosis_owner_id": diagnosis_owner_id ?? 0,
        "diagnosis_category_id": diagnosis_category_id ?? 0,
        "diagnosis_preparation_time": diagnosis_preparation_time ?? "",
        "diagnosis_name": diagnosis_name ?? "",
        "diagnosis_description": diagnosis_description ?? "",
        "diagnosis_instructions": diagnosis_instruction ?? "",
      },
      "image": {
        "id_diagnosis_image": id_diagnosis_image ?? 0,
        "diagnosis_image_data": diagnosis_image_data != null
            ? base64Encode(diagnosis_image_data!)
            : null,
        "diagnosis_ref_id": id_diagnosis ?? 0
      }
    };
  }
}

class DiagnosisCategory {
  final int diagnosis_category_id;
  final String diagnosis_category_desc;
  DiagnosisCategory(
      {required this.diagnosis_category_id,
      required this.diagnosis_category_desc});

  factory DiagnosisCategory.fromJson(Map<String, dynamic> json) {
    return DiagnosisCategory(
        diagnosis_category_id: json['id_diagnosis_category'] ?? 0,
        diagnosis_category_desc: json['diagnosis_category_desc'] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis_category_id': diagnosis_category_id,
      'diagnosis_category_desc': diagnosis_category_desc,
    };
  }
}
