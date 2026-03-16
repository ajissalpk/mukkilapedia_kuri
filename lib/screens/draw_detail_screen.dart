import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:intl/intl.dart';
import '../providers/draw_provider.dart';
import '../models/draw.dart';
import '../models/member.dart';
import '../models/winner.dart';
import '../utils/responsive_utils.dart';
import 'spin_screen.dart';
import 'winners_screen.dart';

class DrawDetailScreen extends StatelessWidget {
  final String drawId;

  const DrawDetailScreen({super.key, required this.drawId});

  @override
  Widget build(BuildContext context) {
    // Listen to provider updates (e.g. when member added or removed)
    final provider = Provider.of<DrawProvider>(context);
    // Find the specific draw safely
    final Draw? draw = provider.draws.where((d) => d.id == drawId).firstOrNull;


    if (draw == null) {
      return const Scaffold(body: Center(child: Text("Draw not found")));
    }
    final eligibleMembers = (draw.members ?? [])
        .where((m) => m.isPaid && !(draw.winners ?? []).any((w) => w.member.id == m.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(draw.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: () {
               _shareReport(context, draw);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Winners History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WinnersScreen(drawId: drawId)),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
               const PopupMenuItem(value: 'reset', child: Row(children: [
                   Icon(Icons.refresh, color: Colors.orange), 
                   SizedBox(width: 8), 
                   Text('Reset All Payment')
               ])),
            ],
            onSelected: (val) {
                if (val == 'reset') {
                   _showResetConfirmDialog(context, provider);
                }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: EdgeInsets.all(context.responsive.spacing(16)),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, "Members", draw.members.length.toString()),
                _buildStatItem(context, "Winners", draw.winners.length.toString()),
                _buildStatItem(context, "Eligible", draw.activeMembers.length.toString(), color: Colors.green),
              ],
            ),
          ),
          if (draw.entryAmount != null)
             Container(
                 width: double.infinity,
                 padding: EdgeInsets.symmetric(vertical: context.responsive.spacing(4)),
                 color: Colors.amber.withOpacity(0.1),
                 child: Text(
                     "${draw.frequency.name[0].toUpperCase()}${draw.frequency.name.substring(1)} Amount: ₹${draw.entryAmount}", 
                     textAlign: TextAlign.center, 
                     style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: context.responsive.fontSize(14))
                 ),
             ),

          const Divider(height: 1),
          // Member List
          Expanded(
            child: draw.members.isEmpty
                ? const Center(child: Text("Add members to start!"))
                : ListView.separated(
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemCount: draw.members.length,
                    itemBuilder: (context, index) {
                       final member = draw.members[index];
                       final isCaptain = member.id == draw.captainId;
                       final isWinner = draw.winners.any((w) => w.member.id == member.id);
                       final isPaid = member.isPaid;
                       final responsive = context.responsive;

                       return ListTile(
                         contentPadding: EdgeInsets.symmetric(
                           horizontal: responsive.spacing(16),
                           vertical: responsive.spacing(8),
                         ),
                         leading: GestureDetector(
                             onTap: () {
                                 // Toggle Captain
                                 if (!isWinner) provider.setCaptain(drawId, member.id);
                             },
                             child: CircleAvatar(
                                 backgroundColor: isCaptain ? Colors.amber : (isWinner ? Colors.grey : (isPaid ? Colors.green : Colors.red.withOpacity(0.5))),
                                 radius: responsive.iconSize(20),
                                 child: Icon(
                                     isCaptain ? Icons.star : (isWinner ? Icons.emoji_events : (isPaid ? Icons.check : Icons.close)),
                                     color: Colors.white,
                                     size: responsive.iconSize(20),
                                 ),
                             ),
                         ),
                         title: Text(
                           member.name,
                           style: TextStyle(
                             decoration: isWinner ? TextDecoration.lineThrough : null,
                             color: isWinner ? Colors.grey : null,
                             fontWeight: isCaptain ? FontWeight.bold : FontWeight.normal,
                             fontSize: responsive.fontSize(16),
                           ),
                         ),
                         subtitle: Text(
                             (isCaptain && isWinner) 
                                 ? "CAPTAIN • WINNER" 
                                 : (isCaptain ? "CAPTAIN" : (isWinner ? "WINNER" : (isPaid ? "Paid" : "Not Paid"))),
                             style: TextStyle(
                                 color: (isCaptain || isWinner) ? Colors.amber : (isPaid ? Colors.green : Colors.red),
                                 fontSize: responsive.fontSize(12),
                                 fontWeight: (isCaptain || isWinner) ? FontWeight.bold : FontWeight.normal
                             )
                         ),
                         trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                 // Payment Checkbox - Enabled for EVERYONE now
                                 Transform.scale(
                                   scale: responsive.spacing(1.0),
                                   child: Checkbox(
                                       value: isPaid,
                                       activeColor: Colors.green,
                                       onChanged: (val) {
                                           provider.toggleMemberPayment(drawId, member.id);
                                       },
                                   ),
                                 ),
                                 PopupMenuButton(
                                   icon: Icon(Icons.more_vert, size: responsive.iconSize(20)),
                                   itemBuilder: (context) => [
                                     if (!isCaptain && !isWinner)
                                       const PopupMenuItem(value: 'captain', child: Text('Make Captain')),
                                     const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                     const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                   ],
                                   onSelected: (value) {
                                      if (value == 'captain') {
                                        provider.setCaptain(drawId, member.id);
                                      } else if (value == 'edit') {
                                        _showEditMemberDialog(context, provider, member);
                                      } else if (value == 'delete') {
                                        provider.removeMemberFromDraw(drawId, member.id);
                                      }
                                   },
                                 ),
                             ],
                         ),
                       );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Builder(
        builder: (context) {
          final responsive = context.responsive;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(24.0)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // LEFT SIDE: Action Buttons (Spin / Manual / Finish)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // CASE 1: Normal Play (More than 1 active member left)
                     if ((draw.members.length - draw.winners.length) > 1) ...[
                          // Manual Winner Button (Only for Captain)
                         if (draw.activeMembers.isNotEmpty && draw.captainId != null) ...[
                            FloatingActionButton.extended(
                               heroTag: "manual_win",
                               backgroundColor: Colors.deepPurple,
                               onPressed: () => _showManualWinnerDialog(context, provider, draw),
                               label: Text("MANUAL WIN", style: TextStyle(fontSize: responsive.fontSize(13))),
                               icon: Icon(Icons.touch_app, size: responsive.iconSize(20)),
                            ),
                            SizedBox(height: responsive.spacing(16)),
                         ],
                         
                        FloatingActionButton.extended(
                          heroTag: "spin",
                          backgroundColor: (draw.captainId != null && draw.activeMembers.isNotEmpty) ? Colors.amber : Colors.grey,
                          onPressed: (draw.captainId == null) 
                              ? () => _showErrorDialog(context, "No Captain Selected!", "Please assign a Captain before spinning.")
                              : (draw.activeMembers.isEmpty 
                                  ? () => _showErrorDialog(context, "No Eligible Members", "No members have PAID yet (or all have won). Mark payments to proceed.")
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => SpinScreen(drawId: drawId)),
                                      ).then((value) {
                                          // If a winner was selected in SpinScreen, payments reset automatically there.
                                      });
                                    }
                                ),
                          label: Text("SPIN CHECK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(13))),
                          icon: Icon(draw.captainId != null ? Icons.verified_user : Icons.warning_amber_rounded, color: Colors.black, size: responsive.iconSize(20)),
                        ),
                     ],

                     // CASE 2: Final Turn (Only 1 active member left)
                     if ((draw.members.length - draw.winners.length) == 1 && draw.activeMembers.isNotEmpty)
                         FloatingActionButton.extended(
                             heroTag: "finish_draw",
                             backgroundColor: Colors.green,
                             onPressed: () {
                                 final lastMember = draw.activeMembers.first;
                                 if (!lastMember.isPaid) {
                                     _showErrorDialog(context, "Payment Pending", "${lastMember.name} must pay before claiming the final pot!");
                                 } else {
                                     _confirmManualWinner(context, provider, draw, lastMember, isFinal: true);
                                 }
                             },
                             label: Text("FINISH DRAW", style: TextStyle(fontSize: responsive.fontSize(13))),
                             icon: Icon(Icons.flag, size: responsive.iconSize(20)),
                         ),
                  ],
                ),

                // RIGHT SIDE: Add Member (Improved Design)
                FloatingActionButton.extended(
                  heroTag: "add",
                  onPressed: () => _showAddMemberDialog(context, provider),
                  backgroundColor: const Color(0xFF00E676), // Bright Neo-Green
                  elevation: 8,
                  icon: Icon(Icons.person_add, color: Colors.black, size: responsive.iconSize(20)),
                  label: Text("ADD MEMBER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(13))),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showManualWinnerDialog(BuildContext context, DrawProvider provider, Draw draw) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text("Select Manual Winner", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: draw.activeMembers.length,
                      itemBuilder: (context, index) {
                          final member = draw.activeMembers[index];
                          return ListTile(
                              leading: CircleAvatar(child: Text(member.name[0])),
                              title: Text(member.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                  Navigator.pop(ctx);
                                  _confirmManualWinner(context, provider, draw, member);
                              },
                          );
                      }
                  ),
              ),
              actions: [
                  TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel"))
              ],
          )
      );
  }

  void _confirmManualWinner(BuildContext context, DrawProvider provider, Draw draw, Member member, {bool isFinal = false}) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: Text(isFinal ? "Finish Draw?" : "Confirm Winner"),
              content: Text(isFinal 
                  ? "Declare '${member.name}' as the FINAL winner and complete the draw?" 
                  : "Declare '${member.name}' as the winner of this draw?"),
              actions: [
                  TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      onPressed: () {
                           // Close confirmation dialog first
                           Navigator.pop(ctx);
                           
                           // Record the winner (this may trigger a rebuild)
                           final prize = draw.defaultPrize ?? "Winner of Draw ${draw.name}"; 
                           final winner = Winner(
                                  member: member,
                                  date: DateTime.now(),
                                  prize: prize + (isFinal ? " (Final)" : " (Manual)")
                           );
                           provider.recordWinner(draw.id, winner);
                           
                           // Use post-frame callback to show celebration dialog after rebuild
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                             if (context.mounted) {
                               _showCelebrationDialog(context, member, isFinal);
                             }
                           });
                      },
                      child: Text(isFinal ? "Finish & Win" : "Confirm Win")
                  )
              ],
          )
      );
  }

  void _showResetConfirmDialog(BuildContext context, DrawProvider provider) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text("Reset All Payments?"),
              content: const Text("This will uncheck 'Paid' for ALL members.\n\nDo this only AFTER you have shared the report."),
              actions: [
                  TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                      onPressed: () {
                          provider.resetPayments(drawId);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payments Reset! Ready for next round.")));
                      },
                      child: const Text("Reset Now")
                  )
              ],
          )
      );
  }

  void _showCelebrationDialog(BuildContext context, Member winner, bool isFinal) {
      final responsive = context.responsive;
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(20))),
              title: Center(child: Text("🎉 CONGRATULATIONS! 🎉", style: TextStyle(fontSize: responsive.fontSize(18)))),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      CircleAvatar(
                        radius: responsive.iconSize(40),
                        backgroundColor: Colors.amber,
                        child: Text(winner.name[0], style: TextStyle(fontSize: responsive.fontSize(40), color: Colors.white)),
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      Text(
                          winner.name,
                          style: TextStyle(fontSize: responsive.fontSize(32), fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      Text(
                          isFinal ? "Has won the FINAL pot! The draw is now complete." : "Selected as the Winner!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(14))
                      ),
                  ],
              ),
              actions: [
                  Center(
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("Awesome!", style: TextStyle(fontSize: responsive.fontSize(16))),
                    ),
                  )
              ],
          )
      );
  }


  Widget _buildStatItem(BuildContext context, String label, String value, {Color? color}) {
    final responsive = context.responsive;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: responsive.fontSize(20), fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: responsive.fontSize(12), color: Colors.grey)),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context, DrawProvider provider) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Member Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newMember = Member.create(name: nameController.text);
                provider.addMemberToDraw(drawId, newMember);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, DrawProvider provider, Member member) {
    final nameController = TextEditingController(text: member.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Member"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Member Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // Create a copy with new name but same ID
                final updatedMember = Member(
                  id: member.id,
                  name: nameController.text,
                  phone: member.phone,
                  isPaid: member.isPaid,
                );
                provider.updateMember(drawId, updatedMember);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _shareReport(BuildContext context, Draw draw) {
      final total = draw.members.length;
      final paid = draw.members.where((m) => m.isPaid).length;
      
      final buffer = StringBuffer();
      buffer.writeln("📢 *${draw.name.toUpperCase()} REPORT* 📢");
      if (draw.entryAmount != null) buffer.writeln("💰 Amount: ₹${draw.entryAmount}");
      buffer.writeln("📅 Status: $paid/$total Paid");
      buffer.writeln("--------------------------------");
      
      if (draw.defaultPrize != null) buffer.writeln("🏆 Prize: ${draw.defaultPrize}");
      if (draw.captainId != null) {
          final captain = draw.members.firstWhere((m) => m.id == draw.captainId);
          buffer.writeln("⭐ Captain: ${captain.name}");
      }
      buffer.writeln("--------------------------------");
      
      buffer.writeln("📋 *Members List:*");
      for (var m in draw.members) {
          final status = m.isPaid ? "✅ Paid" : "❌ Due";
          String winnerInfo = "";
          
          try {
              final winner = draw.winners.firstWhere((w) => w.member.id == m.id);
              final dateStr = DateFormat('dd MMM, hh:mm a').format(winner.date);
              // Extract type from prize string if possible or infer
              // We saved it as "Prize (Manual)" or "Prize (Final)"
              // Let's just show the prize string which contains the method
              winnerInfo = " \n   🏆 WON: ${winner.prize}\n   $dateStr";
          } catch (e) {
              // Not a winner
          }
          buffer.writeln("- ${m.name}: $status$winnerInfo");
      }
      
      buffer.writeln("\nPowered by Mukkilapedia Team");

      Share.share(buffer.toString());
  }

  void _showErrorDialog(BuildContext context, String title, String msg) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.red)),
          content: Text(msg),
          actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.white)))]
      ));
  }
}
