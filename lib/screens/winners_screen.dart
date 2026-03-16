import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/draw_provider.dart';
import '../utils/responsive_utils.dart';

class WinnersScreen extends StatelessWidget {
  final String drawId;
  const WinnersScreen({super.key, required this.drawId});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final provider = Provider.of<DrawProvider>(context);
    final draw = provider.draws.firstWhere((d) => d.id == drawId);

    return Scaffold(
      appBar: AppBar(title: const Text("Winners History")),
      body: draw.winners.isEmpty
          ? const Center(child: Text("No winners yet!"))
          : ListView.builder(
              padding: EdgeInsets.all(responsive.spacing(8)),
              itemCount: draw.winners.length,
              itemBuilder: (context, index) {
                final winner = draw.winners[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(16),
                    vertical: responsive.spacing(8),
                  ),
                  leading: Icon(Icons.emoji_events, color: Colors.amber, size: responsive.iconSize(40)),
                  title: Text(winner.member.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.fontSize(16))),
                  subtitle: Text(DateFormat.yMMMd().add_jm().format(winner.date), style: TextStyle(fontSize: responsive.fontSize(13))),
                  trailing: Text(winner.prize, style: TextStyle(fontSize: responsive.fontSize(14))),
                );
              },
            ),
    );
  }
}
