import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:confetti/confetti.dart';
import '../providers/draw_provider.dart';
import '../models/draw.dart';
import '../models/winner.dart';
import '../utils/responsive_utils.dart';

class SpinScreen extends StatefulWidget {
  final String drawId;
  const SpinScreen({super.key, required this.drawId});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  StreamController<int> selected = StreamController<int>();
  late ConfettiController _confettiController;
  // REMOVED AudioPlayer

  bool isSpinning = false;
  bool isGenuineMode = false;

  final List<Color> _wheelColors = [
    Color(0xFFFF5733), // Red-Orange
    Color(0xFF33FF57), // Green
    Color(0xFF3357FF), // Blue
    Color(0xFFFF33A1), // Pink
    Color(0xFF33FFF5), // Cyan
    Color(0xFFF5FF33), // Yellow
    Color(0xFFA133FF), // Purple
    Color(0xFFFF8C33), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // REMOVED Audio Preload
  }

  @override
  void dispose() {
    selected.close();
    _confettiController.dispose();
    // REMOVED audio dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // LISTEN: FALSE to prevent rebuilds when winner is recorded (which removes member)
    // This prevents the "RangeError" crash when items count changes abruptly
    final provider = Provider.of<DrawProvider>(context, listen: false); 
    
    // We assume the draw exists because we navigated here.
    // If it was deleted, this might throw, but standard nav handling covers it.
    final draw = provider.draws.firstWhere((d) => d.id == widget.drawId);
    
    // We capture the items list AT BUILD TIME. Even if provider updates later, 
    // this local variable won't change until we decide to rebuild (which we won't do on recordWinner due to listen:false)
    final items = draw.activeMembers; 

    if (items.isEmpty) {
        return Scaffold(appBar: AppBar(), body: const Center(child: Text("No active members left!")));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("LUCKY DRAW SPIN", style: TextStyle(fontSize: responsive.fontSize(20))),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Control Bar
              Padding(
                padding: EdgeInsets.all(responsive.spacing(16.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("MODE: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.fontSize(14))),
                    Switch(
                      value: isGenuineMode,
                      onChanged: isSpinning ? null : (val) => setState(() => isGenuineMode = val),
                      activeColor: Colors.red,
                    ),
                    Text(
                      isGenuineMode ? "GENUINE" : "TRIAL",
                      style: TextStyle(
                        color: isGenuineMode ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize(14),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isGenuineMode)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16.0)),
                  child: Text(
                    "WARNING: Genuine Mode will remove the winner from this wheel forever!",
                    style: TextStyle(color: Colors.red, fontSize: responsive.fontSize(12)),
                  ),
                ),

                  Expanded(
                child: Padding(
                  padding: EdgeInsets.all(responsive.spacing(20.0)),
                  child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative outer ring
                        Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                    BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: responsive.spacing(20), spreadRadius: responsive.spacing(5))
                                ]
                            ),
                        ),
                        FortuneWheel(
                            selected: selected.stream,
                            animateFirst: false,
                            physics: CircularPanPhysics(
                              duration: const Duration(seconds: 1),
                              curve: Curves.decelerate,
                            ),
                            duration: const Duration(seconds: 10), 
                            onAnimationEnd: () {
                                setState(() => isSpinning = false);
                            },
                            items: [
                              for (int i = 0; i < items.length; i++)
                                FortuneItem(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: responsive.spacing(10.0)),
                                    child: Text(
                                      items[i].name, 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: responsive.fontSize(16))
                                    ),
                                  ),
                                  style: FortuneItemStyle(
                                    color: _wheelColors[i % _wheelColors.length],
                                    borderColor: Colors.amber.withOpacity(0.5), // Gold border
                                    borderWidth: responsive.spacing(2),
                                  ),
                                ),
                            ],
                        ),
                         // Center Logo / Indicator
                        Container(
                          width: responsive.sizeFromMinDimension(8),
                          height: responsive.sizeFromMinDimension(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            border: Border.all(color: Colors.amber, width: responsive.spacing(3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: responsive.spacing(10),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/app_logo.jpg",
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      ]
                  ),
                ),
              ),
              
              if (draw.defaultPrize != null)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(10)),
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20), vertical: responsive.spacing(8)),
                          decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(responsive.spacing(20)),
                              border: Border.all(color: Colors.amber)
                          ),
                          child: Text(
                              "🏆 WIN: ${draw.defaultPrize}", 
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(18))
                          ),
                      )
                  ),
              
              SizedBox(height: responsive.spacing(20)),
              
              Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(50.0)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.identity()..scale(isSpinning ? 0.95 : 1.0),
                  child: ElevatedButton(
                    onPressed: isSpinning ? null : () {
                      setState(() => isSpinning = true);
                      
                      final index = Random().nextInt(items.length);
                      selected.add(index);
                      
                      Future.delayed(const Duration(seconds: 10), () {
                          // REMOVED Audio Logic
                          _showResult(context, provider, draw, items[index]);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(50), vertical: responsive.spacing(20)),
                      backgroundColor: isGenuineMode ? const Color(0xFFD32F2F) : const Color(0xFF388E3C), // Darker Red/Green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(30))),
                      elevation: 10,
                      shadowColor: isGenuineMode ? Colors.redAccent : Colors.greenAccent,
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Icon(Icons.touch_app, size: responsive.iconSize(28)),
                            SizedBox(width: responsive.spacing(10)),
                            Text(
                              isGenuineMode ? "SPIN NOW" : "TEST SPIN",
                              style: TextStyle(fontSize: responsive.fontSize(22), fontWeight: FontWeight.bold),
                            ),
                        ]
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, DrawProvider provider, Draw draw, var winnerMember) {
      final responsive = context.responsive;
      if (isGenuineMode) {
          _confettiController.play();
      }

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(20))),
              title: Center(child: Text("🎉 WE HAVE A WINNER! 🎉", style: TextStyle(fontSize: responsive.fontSize(18)))),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      CircleAvatar(
                        radius: responsive.iconSize(40),
                        backgroundColor: Colors.amber,
                        child: Text(winnerMember.name[0], style: TextStyle(fontSize: responsive.fontSize(40), color: Colors.white)),
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      Text(
                          winnerMember.name,
                          style: TextStyle(fontSize: responsive.fontSize(32), fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      if (isGenuineMode)
                        Text("Winner record saved!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(14)))
                      else
                        Text("Trial Spin - No Result Saved", style: TextStyle(color: Colors.grey, fontSize: responsive.fontSize(14))),
                  ],
              ),
              actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber, 
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(30), vertical: responsive.spacing(12))
                      ),
                      onPressed: () {
                          if (isGenuineMode) {
                              final prize = draw.defaultPrize ?? "Winner of Draw ${draw.name}"; 
                              final winner = Winner(
                                  member: winnerMember,
                                  date: DateTime.now(),
                                  prize: prize
                              );
                              // This updates state.
                              provider.recordWinner(draw.id, winner);
                              
                              Navigator.pop(ctx); 
                              Navigator.pop(context); // Go back to Detail Screen
                          } else {
                              Navigator.pop(ctx);
                          }
                      },
                      child: Text("Awesome!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.fontSize(16))),
                  )
              ],
          )
      );
  }
}
