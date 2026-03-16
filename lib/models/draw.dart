import 'package:uuid/uuid.dart';
import 'member.dart';
import 'winner.dart';

enum DrawFrequency { weekly, monthly, custom }

class Draw {
  final String id;
  String name;
  DrawFrequency frequency;
  List<Member> members;
  List<Winner> winners;
  String? captainId; // ID of the member who is the captain
  String? defaultPrize; // Prize for this draw
  double? entryAmount; // Amount to be paid

  Draw({
    required this.id,
    required this.name,
    required this.frequency,
    List<Member>? members,
    List<Winner>? winners,
    this.captainId,
    this.defaultPrize,
    this.entryAmount,
  })  : members = members ?? [],
        winners = winners ?? [];

  factory Draw.create({
    required String name,
    required DrawFrequency frequency,
    String? defaultPrize,
    double? entryAmount,
  }) {
    return Draw(
      id: const Uuid().v4(),
      name: name,
      frequency: frequency,
      defaultPrize: defaultPrize,
      entryAmount: entryAmount,
    );
  }

  // Get active members (those who haven't won yet AND have paid)
  List<Member> get activeMembers {
    final winnerIds = winners.map((w) => w.member.id).toSet();
    // Only return members who are NOT winners AND have PAID
    return members.where((m) => !winnerIds.contains(m.id) && m.isPaid).toList();
  }

  // Draw is completed when 1 or fewer active members remain
  // Note: Depending on logic, if people haven't paid, they aren't "active". 
  // But completion usually means "only 1 person left to win".
  // For now, let's keep isCompleted based on TOTAL potential members minus winners.
  bool get isCompleted => (members.length - winners.length) <= 1 && members.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency.index,
      'members': members.map((m) => m.toJson()).toList(),
      'winners': winners.map((w) => w.toJson()).toList(),
      'captainId': captainId,
      'defaultPrize': defaultPrize,
      'entryAmount': entryAmount,
    };
  }

  factory Draw.fromJson(Map<String, dynamic> json) {
    return Draw(
      id: json['id'],
      name: json['name'],
      frequency: DrawFrequency.values[json['frequency']],
      members: (json['members'] as List).map((m) => Member.fromJson(m)).toList(),
      winners: (json['winners'] as List).map((w) => Winner.fromJson(w)).toList(),
      captainId: json['captainId'],
      defaultPrize: json['defaultPrize'],
      entryAmount: json['entryAmount'] != null ? (json['entryAmount'] as num).toDouble() : null,
    );
  }
}
