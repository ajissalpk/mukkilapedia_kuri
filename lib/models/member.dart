import 'package:uuid/uuid.dart';

class Member {
  final String id;
  String name;
  String? phone; // Optional
  bool isPaid;

  Member({
    required this.id,
    required this.name,
    this.phone,
    this.isPaid = false,
  });

  factory Member.create({required String name, String? phone}) {
    return Member(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      isPaid: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isPaid': isPaid,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      isPaid: json['isPaid'] ?? false,
    );
  }
}
