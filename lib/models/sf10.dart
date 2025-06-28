// lib/models/sf10.dart

class SF10 {
  String id;
  String studentName;
  String dateIssued;

  SF10({
    required this.id,
    required this.studentName,
    required this.dateIssued,
  });

  Map<String, String> toJson() => {
        'id': id,
        'studentName': studentName,
        'dateIssued': dateIssued,
      };

  factory SF10.fromJson(Map<String, dynamic> json) => SF10(
        id: json['id'] as String,
        studentName: json['studentName'] as String,
        dateIssued: json['dateIssued'] as String,
      );
}
