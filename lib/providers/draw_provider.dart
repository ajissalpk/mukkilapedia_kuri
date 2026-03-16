import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draw.dart';
import '../models/member.dart';
import '../models/winner.dart';

class DrawProvider with ChangeNotifier {
  List<Draw> _draws = [];

  List<Draw> get draws => _draws;

  static const String _storageKey = 'mukkilapedia_draws_data';

  DrawProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        _draws = decoded.map((e) => Draw.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        print("Error loading data: $e");
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_draws.map((d) => d.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // Draw Management
  void addDraw(String name, DrawFrequency frequency, {String? defaultPrize, double? entryAmount}) {
    _draws.add(Draw.create(name: name, frequency: frequency, defaultPrize: defaultPrize, entryAmount: entryAmount));
    _saveData();
    notifyListeners();
  }

  void updateDraw(Draw draw) {
      // Find and replace by ID or since objects are mutable in memory,
      // if we passed the reference it might be updated.
      // But best practice is to explicit trigger save.
      final index = _draws.indexWhere((d) => d.id == draw.id);
      if (index != -1) {
          _draws[index] = draw;
          _saveData();
          notifyListeners();
      }
  }

  void deleteDraw(String id) {
    _draws.removeWhere((d) => d.id == id);
    _saveData();
    notifyListeners();
  }

  // Member Management
  void addMemberToDraw(String drawId, Member member) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    draw.members.add(member);
    updateDraw(draw);
  }

  void updateMember(String drawId, Member updatedMember) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    final index = draw.members.indexWhere((m) => m.id == updatedMember.id);
    if (index != -1) {
      draw.members[index] = updatedMember;
      updateDraw(draw);
    }
  }

  void toggleMemberPayment(String drawId, String memberId) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    final index = draw.members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      draw.members[index].isPaid = !draw.members[index].isPaid;
      updateDraw(draw);
    }
  }

  void resetPayments(String drawId) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    for (var m in draw.members) {
      m.isPaid = false;
    }
    updateDraw(draw);
  }

  void removeMemberFromDraw(String drawId, String memberId) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    draw.members.removeWhere((m) => m.id == memberId);
    // If successful, also check if they were captain, remove if so?
    if (draw.captainId == memberId) {
      draw.captainId = null;
    }
    updateDraw(draw);
  }

  void setCaptain(String drawId, String memberId) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    // Ensure member exists
    if (draw.members.any((m) => m.id == memberId)) {
      draw.captainId = memberId;
      updateDraw(draw);
    }
  }

  // Winner Management
  void recordWinner(String drawId, Winner winner) {
    final draw = _draws.firstWhere((d) => d.id == drawId);
    draw.winners.insert(0, winner); // Add to top of list
    // Note: Active members getter logic handles exclusion.
    // If you explicitly want to REMOVE from members list forever:
    // draw.members.removeWhere((m) => m.id == winner.member.id);
    // But user requirement says "remove from that spin wheel", usually implying
    // they are still a member, just "won already".
    // "remove from that spin wheel" -> Handled by `activeMembers` getter in Draw model
    updateDraw(draw);
  }
}
