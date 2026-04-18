import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/draw_provider.dart';
import '../models/draw.dart';
import '../models/winner.dart';
import '../utils/responsive_utils.dart';
import 'draw_detail_screen.dart';

class SpinScreen extends StatefulWidget {
  final String drawId;
  const SpinScreen({super.key, required this.drawId});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  StreamController<int> selected = StreamController<int>();
  late ConfettiController _confettiController;

  bool isSpinning = false;
  bool isGenuineMode = false;
  bool _isRecording = false;
  bool _recordingConfirmed = false;

  final List<Color> _wheelColors = [
    Color(0xFFFF5733), Color(0xFF33FF57), Color(0xFF3357FF),
    Color(0xFFFF33A1), Color(0xFF33FFF5), Color(0xFFF5FF33),
    Color(0xFFA133FF), Color(0xFFFF8C33),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    if (_isRecording) {
      FlutterScreenRecording.stopRecordScreen; // best-effort cleanup
    }
    selected.close();
    _confettiController.dispose();
    super.dispose();
  }

  // ─── Request permissions (Android + iOS) ──────────────────────────────────
  Future<bool> _requestRecordingPermissions() async {
    // Microphone is needed on both platforms
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Microphone permission denied. Cannot record."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // Storage permissions — Android only, version-aware
    final storageStatus = await Permission.storage.request();
    // On Android 13+ storage permission is deprecated but won't block recording
    // so we allow even if denied
    return true;
  }

  // ─── Toggle handler ────────────────────────────────────────────────────────
  Future<void> _onToggleChanged(bool value) async {
    if (value) {
      final confirmed = await _showRecordConfirmDialog();

      if (confirmed == true) {
        // Request permissions first
        final hasPermission = await _requestRecordingPermissions();
        if (!hasPermission) {
          setState(() {
            isGenuineMode = true;
            _recordingConfirmed = false;
          });
          return;
        }

        final started = await FlutterScreenRecording.startRecordScreen(
          "lucky_draw_${DateTime.now().millisecondsSinceEpoch}",
          titleNotification: "Lucky Draw Recording",
          messageNotification: "Recording in progress...",
        );

        if (started) {
          setState(() {
            isGenuineMode = true;
            _isRecording = true;
            _recordingConfirmed = true;
          });
        } else {
          setState(() {
            isGenuineMode = true;
            _recordingConfirmed = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Could not start recording. Proceeding without video."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() {
          isGenuineMode = true;
          _recordingConfirmed = false;
        });
      }
    } else {
      if (_isRecording) {
        final path = await FlutterScreenRecording.stopRecordScreen;
        setState(() => _isRecording = false);
        if (mounted && path.isNotEmpty) {
          final provider = Provider.of<DrawProvider>(context, listen: false);
          final draw = provider.draws.firstWhere((d) => d.id == widget.drawId);
          _showVideoSavedDialog(path, draw);
        }
      }
      setState(() {
        isGenuineMode = false;
        _recordingConfirmed = false;
      });
    }
  }

  // ─── Stop recording and show save dialog ──────────────────────────────────
  Future<void> _stopRecordingIfActive() async {
    if (_isRecording) {
      // stopRecordScreen returns the file path
      final String path = await FlutterScreenRecording.stopRecordScreen;
      setState(() {
        _isRecording = false;
        _recordingConfirmed = false;
      });
      if (mounted && path.isNotEmpty) {
        final provider = Provider.of<DrawProvider>(context, listen: false);
        final draw = provider.draws.firstWhere((d) => d.id == widget.drawId);
        _showVideoSavedDialog(path, draw);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recording stopped but file path not found."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ─── Video saved dialog with Play + Share ─────────────────────────────────
  void _showVideoSavedDialog(String path, Draw draw) {
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: responsive.iconSize(24)),
            SizedBox(width: responsive.spacing(8)),
            Text(
              "Video Saved!",
              style: TextStyle(fontSize: responsive.fontSize(18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your lucky draw spin has been recorded and saved.",
              style: TextStyle(fontSize: responsive.fontSize(13)),
            ),
            SizedBox(height: responsive.spacing(10)),
            // Show the file path in a small box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(8)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(responsive.spacing(6)),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                path,
                style: TextStyle(
                  fontSize: responsive.fontSize(10),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Dismiss
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close video saved dialog
              Navigator.pop(context); // Close spin screen
            },
            child: Text(
              "Dismiss",
              style: TextStyle(
                color: Colors.grey,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
          // Play button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(14),
                vertical: responsive.spacing(8),
              ),
            ),
            icon: Icon(Icons.play_circle_fill, size: responsive.iconSize(16)),
            label: Text(
              "Play",
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close spin screen
              OpenFile.open(path);
            },
          ),
          // Share button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(14),
                vertical: responsive.spacing(8),
              ),
            ),
            icon: Icon(Icons.share, size: responsive.iconSize(16)),
            label: Text(
              "Share",
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close spin screen
              Share.shareXFiles(
                [XFile(path)],
                subject: 'Lucky Draw Recording',
                text: DrawDetailScreen.generateReportText(draw),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Record confirm dialog ─────────────────────────────────────────────────
  Future<bool?> _showRecordConfirmDialog() {
    final responsive = context.responsive;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.videocam, color: Colors.red, size: responsive.iconSize(24)),
            SizedBox(width: responsive.spacing(8)),
            Text(
              "Record this spin?",
              style: TextStyle(fontSize: responsive.fontSize(18)),
            ),
          ],
        ),
        content: Text(
          "The wheel spin and winner reveal will be recorded as a video and saved to your gallery.",
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "No, skip",
              style: TextStyle(color: Colors.grey, fontSize: responsive.fontSize(14)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(20),
                vertical: responsive.spacing(10),
              ),
            ),
            icon: Icon(Icons.fiber_manual_record, size: responsive.iconSize(16)),
            label: Text(
              "Yes, record!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize(14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final provider = Provider.of<DrawProvider>(context, listen: false);
    final draw = provider.draws.firstWhere((d) => d.id == widget.drawId);
    final items = draw.activeMembers;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No active members left!")),
      );
    }

    // FortuneWheel requires at least 2 items. If only 1 member is left, duplicate it dynamically.
    final wheelItems = items.length == 1 ? [items.first, items.first] : items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "LUCKY DRAW SPIN",
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
        centerTitle: true,
        actions: [
          if (_isRecording)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(12),
                vertical: responsive.spacing(14),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(8),
                  vertical: responsive.spacing(2),
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(responsive.spacing(4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: responsive.iconSize(10)),
                    SizedBox(width: responsive.spacing(4)),
                    Text(
                      "REC",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(responsive.spacing(16.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "MODE: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize(14),
                      ),
                    ),
                    Switch(
                      value: isGenuineMode,
                      onChanged: (isSpinning || _isRecording) ? null : _onToggleChanged,
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
                    if (isGenuineMode && !_isRecording) ...[
                      SizedBox(width: responsive.spacing(8)),
                      Icon(Icons.videocam_off,
                          size: responsive.iconSize(16), color: Colors.grey),
                    ],
                  ],
                ),
              ),

              if (isGenuineMode)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16.0)),
                  child: Text(
                    _recordingConfirmed
                        ? "🔴 Recording ON — spin and winner will be captured"
                        : "⚠️ WARNING: Genuine Mode will remove the winner from this wheel forever!",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: responsive.fontSize(12),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(responsive.spacing(20.0)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: responsive.spacing(20),
                              spreadRadius: responsive.spacing(5),
                            )
                          ],
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
                          for (int i = 0; i < wheelItems.length; i++)
                            FortuneItem(
                              child: Padding(
                                padding: EdgeInsets.only(left: responsive.spacing(10.0)),
                                child: Text(
                                  wheelItems[i].name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: responsive.fontSize(16),
                                  ),
                                ),
                              ),
                              style: FortuneItemStyle(
                                color: _wheelColors[i % _wheelColors.length],
                                borderColor: Colors.amber.withOpacity(0.5),
                                borderWidth: responsive.spacing(2),
                              ),
                            ),
                        ],
                      ),
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
                      ),
                    ],
                  ),
                ),
              ),

              if (draw.defaultPrize != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: responsive.spacing(10)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(20),
                      vertical: responsive.spacing(8),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(responsive.spacing(20)),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      "WIN: ${draw.defaultPrize}",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize(18),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: responsive.spacing(20)),

              Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(50.0)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.identity()..scale(isSpinning ? 0.95 : 1.0),
                  child: ElevatedButton(
                    onPressed: isSpinning
                        ? null
                        : () {
                      setState(() => isSpinning = true);
                      final index = Random().nextInt(wheelItems.length);
                      selected.add(index);
                      Future.delayed(const Duration(seconds: 10), () {
                        _showResult(context, provider, draw, wheelItems[index]);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(50),
                        vertical: responsive.spacing(20),
                      ),
                      backgroundColor: isGenuineMode
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(responsive.spacing(30)),
                      ),
                      elevation: 10,
                      shadowColor: isGenuineMode ? Colors.redAccent : Colors.greenAccent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_recordingConfirmed)
                          Padding(
                            padding: EdgeInsets.only(right: responsive.spacing(6)),
                            child: Icon(Icons.videocam,
                                size: responsive.iconSize(20), color: Colors.white),
                          ),
                        Icon(Icons.touch_app, size: responsive.iconSize(28)),
                        SizedBox(width: responsive.spacing(10)),
                        Text(
                          isGenuineMode ? "SPIN NOW" : "TEST SPIN",
                          style: TextStyle(
                            fontSize: responsive.fontSize(22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green, Colors.blue, Colors.pink,
                Colors.orange, Colors.purple,
              ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(20)),
        ),
        title: Center(
          child: Text(
            "WE HAVE A WINNER!",
            style: TextStyle(fontSize: responsive.fontSize(18)),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: responsive.iconSize(40),
              backgroundColor: Colors.amber,
              child: Text(
                winnerMember.name[0],
                style: TextStyle(
                  fontSize: responsive.fontSize(40),
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            Text(
              winnerMember.name,
              style: TextStyle(
                fontSize: responsive.fontSize(32),
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(16)),
            if (isGenuineMode)
              Text(
                "Winner record saved!",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.fontSize(14),
                ),
              )
            else
              Text(
                "Trial Spin - No Result Saved",
                style: TextStyle(color: Colors.grey, fontSize: responsive.fontSize(14)),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(30),
                vertical: responsive.spacing(12),
              ),
            ),
            onPressed: () async {
              if (isGenuineMode) {
                final prize = draw.defaultPrize ?? "Winner of Draw ${draw.name}";
                final winner = Winner(
                  member: winnerMember,
                  date: DateTime.now(),
                  prize: prize,
                );
                provider.recordWinner(draw.id, winner);

                // Close winner dialog first
                Navigator.pop(ctx);

                // Stop recording → this will show the video saved dialog.
                // The video saved dialog will then pop the spin screen when dismissed/shared.
                await _stopRecordingIfActive();
              } else {
                Navigator.pop(ctx);
              }
            },
            child: Text(
              "Awesome!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}