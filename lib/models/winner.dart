import 'package:mukkilapedia_lucky_draw/models/member.dart';

class Winner {
  final Member member;
  final DateTime date;
  final String prize;

  Winner({
    required this.member,
    required this.date,
    required this.prize,
  });

  Map<String, dynamic> toJson() {
    return {
      'member': member.toJson(),
      'date': date.toIso8601String(),
      'prize': prize,
    };
  }

  factory Winner.fromJson(Map<String, dynamic> json) {
    return Winner(
      member: Member.fromJson(json['member']),
      date: DateTime.parse(json['date']),
      prize: json['prize'],
    );
  }
}
