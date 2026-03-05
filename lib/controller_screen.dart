import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_state.dart';
import 'edit_modal.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final GameState _gs = GameState();
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('live');
  final DatabaseReference _bravoRef = FirebaseDatabase.instance.ref('bravo');

  Timer? _mainTimer;
  Timer? _shotTimer;
  DateTime? _mainLast;
  DateTime? _shotLast;
  Timer? _fbThrottle;

  int _prev1 = 0, _prev2 = 0;
  bool _bravoActive = false;

  @override
  void dispose() {
    _mainTimer?.cancel();
    _shotTimer?.cancel();
    _fbThrottle?.cancel();
    super.dispose();
  }

  // ── Firebase ──
  void _push({bool immediate = false}) {
    if (immediate) {
      _doPush();
    } else {
      if (_fbThrottle != null) return;
      _fbThrottle = Timer(const Duration(milliseconds: 200), () {
        _fbThrottle = null;
        _doPush();
      });
    }
  }

  void _doPush() {
    try {
      _ref.set(_gs.toMap());
    } catch (e) {
      debugPrint('Firebase push error: $e');
    }
  }

  // ── Clock controls ──
  void _toggleMainClock() {
    if (_gs.mainRunning) {
      _stopAll();
    } else {
      _startAll();
    }
  }

  void _startAll() {
    _startMain();
    _startShot();
  }

  void _stopAll() {
    _stopMain();
    _stopShot();
    _push(immediate: true);
  }

  void _startMain() {
    if (_gs.mainRunning) return;
    setState(() => _gs.mainRunning = true);
    _mainLast = DateTime.now();
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(_mainLast!).inSeconds;
      _mainLast = now;
      setState(() {
        _gs.mainSec = (_gs.mainSec - elapsed).clamp(0, 9999);
      });
      _push();
      if (_gs.mainSec <= 0) {
        _stopAll();
      }
    });
  }

  void _stopMain() {
    setState(() => _gs.mainRunning = false);
    _mainTimer?.cancel();
    _mainTimer = null;
  }

  void _startShot() {
    if (_gs.shotRunning) return;
    if (_gs.shot <= 0 && _gs.shotMs <= 0) return;
    setState(() => _gs.shotRunning = true);
    _shotLast = DateTime.now();
    _shotTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(_shotLast!).inMilliseconds;
      _shotLast = now;
      int total = _gs.shot * 1000 + _gs.shotMs - elapsed;
      if (total <= 0) {
        total = 0;
        _stopShot();
        _push(immediate: true);
      }
      setState(() {
        _gs.shot = total ~/ 1000;
        _gs.shotMs = total % 1000;
      });
      _push();
    });
  }

  void _stopShot() {
    setState(() => _gs.shotRunning = false);
    _shotTimer?.cancel();
    _shotTimer = null;
  }

  void _setShotClock(int val) {
    _stopShot();
    setState(() {
      _gs.shot = val;
      _gs.shotMs = 0;
    });
    _push(immediate: true);
  }

  void _resetQtrTimer() {
    _stopAll();
    setState(() {
      _gs.mainSec = 600;
      _gs.shot = 24;
      _gs.shotMs = 0;
    });
    _push(immediate: true);
  }

  // ── Score ──
  void _addScore(int team, int pts) {
    setState(() {
      if (team == 1) {
        _prev1 = _gs.sc1;
        _gs.sc1 += pts;
      } else {
        _prev2 = _gs.sc2;
        _gs.sc2 += pts;
      }
    });
    HapticFeedback.lightImpact();
    _push(immediate: true);
  }

  void _undoScore() {
    setState(() {
      _gs.sc1 = _prev1;
      _gs.sc2 = _prev2;
    });
    _push(immediate: true);
  }

  // ── Fouls ──
  void _chgFoul(int team, int d) {
    setState(() {
      if (team == 1) {
        _gs.f1 = (_gs.f1 + d).clamp(0, 99);
      } else {
        _gs.f2 = (_gs.f2 + d).clamp(0, 99);
      }
    });
    _push(immediate: true);
  }

  // ── Dots ──
  void _cycleDot(int team) {
    setState(() {
      if (team == 1) {
        _gs.dt1 = _gs.dt1 >= 4 ? 0 : _gs.dt1 + 1;
      } else {
        _gs.dt2 = _gs.dt2 >= 4 ? 0 : _gs.dt2 + 1;
      }
    });
  }

  // ── Quarter ──
  void _nextQtr() {
    if (_gs.qtr < 4) {
      setState(() => _gs.qtr++);
      _resetQtrTimer();
    }
  }

  void _prevQtr() {
    if (_gs.qtr > 1) {
      setState(() => _gs.qtr--);
      _resetQtrTimer();
    }
  }

  // ── Bravo ──
  void _sendBravo() {
    _bravoRef.set({'ts': DateTime.now().millisecondsSinceEpoch, 'active': true});
    setState(() => _bravoActive = true);
    Future.delayed(const Duration(seconds: 4), () {
      _bravoRef.set({'ts': DateTime.now().millisecondsSinceEpoch, 'active': false});
      if (mounted) setState(() => _bravoActive = false);
    });
  }

  // ── Reset ──
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Reset the whole match?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _doReset();
            },
            child: const Text('Yes, Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _doReset() {
    _stopAll();
    setState(() {
      _gs.sc1 = _gs.sc2 = _gs.f1 = _gs.f2 = _gs.dt1 = _gs.dt2 = 0;
      _prev1 = _prev2 = 0;
      _gs.qtr = 1;
      _gs.mainSec = 600;
      _gs.shot = 24;
      _gs.shotMs = 0;
    });
    _push(immediate: true);
  }

  // ── Edit modal ──
  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditModal(
        gs: _gs,
        onChanged: () {
          setState(() {});
          _push(immediate: true);
        },
        onStopAll: _stopAll,
      ),
    );
  }

  // ── Options ──
  void _showOpts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optBtn('◀ Prev Quarter', () { Navigator.pop(context); _prevQtr(); }),
            const SizedBox(height: 10),
            _optBtn('Next Quarter ▶', () { Navigator.pop(context); _nextQtr(); }),
            const SizedBox(height: 10),
            _optBtn('Reset Timer', () { Navigator.pop(context); _resetQtrTimer(); }),
            const SizedBox(height: 10),
            _optBtn('Reset Match', () { Navigator.pop(context); _confirmReset(); },
                color: Colors.red),
            const SizedBox(height: 10),
            _optBtn('Close', () => Navigator.pop(context), color: Colors.grey[700]!),
          ],
        ),
      ),
    );
  }

  Widget _optBtn(String label, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: color != null ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── UI helpers ──
  Widget _scoreBtn(int team, int pts) {
    return GestureDetector(
      onTap: () => _addScore(team, pts),
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Text('+$pts',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    );
  }

  Widget _dotGroup(int team) {
    final count = team == 1 ? _gs.dt1 : _gs.dt2;
    return GestureDetector(
      onTap: () => setState(() => _cycleDot(team)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) => Container(
            width: 11, height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? Colors.white : const Color(0xFF444444),
              boxShadow: i < count ? [const BoxShadow(color: Colors.white, blurRadius: 4)] : null,
            ),
          )),
        ),
      ),
    );
  }

  Widget _iconBtn(Widget child, VoidCallback onTap, {Color bg = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(child: child),
      ),
    );
  }

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbitron = GoogleFonts.orbitron(fontWeight: FontWeight.w900);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ──
            _buildTopBar(orbitron),
            // ── MAIN CONTENT ──
            Expanded(child: _buildMain(orbitron, size)),
            // ── BOTTOM BAR ──
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                height: 3,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(TextStyle orbitron) {
    // Shot clock color
    Color shotColor = Colors.white;
    if (_gs.shotRunning && _gs.shot >= 5) shotColor = const Color(0xFFe8c000);
    if (_gs.shotRunning && _gs.shot < 5) shotColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Shot clock
          GestureDetector(
            onTap: () {
              if (_gs.shotRunning) _stopShot(); else _startShot();
              _push(immediate: true);
            },
            child: Text(
              _gs.shotClockDisplay,
              style: orbitron.copyWith(
                fontSize: 22,
                color: shotColor,
                letterSpacing: 2,
              ),
            ),
          ),
          // Center: play + main clock + quarter
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconBtn(
                  Text(_gs.mainRunning ? '⏸' : '▶', style: const TextStyle(fontSize: 20)),
                  _toggleMainClock,
                ),
                const SizedBox(width: 10),
                Text(
                  _gs.mainClockDisplay,
                  style: orbitron.copyWith(fontSize: 28, color: Colors.red, letterSpacing: 3),
                ),
                const SizedBox(width: 10),
                Text(
                  _gs.quarterName,
                  style: GoogleFonts.rajdhani(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Right buttons
          Row(
            children: [
              _iconBtn(
                const Text('✏️', style: TextStyle(fontSize: 18)),
                _openEdit,
                bg: const Color(0xFFffcc00),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _sendBravo,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff6600), Color(0xFFffcc00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                      color: _bravoActive ? const Color(0xFFff6600) : Colors.transparent,
                      blurRadius: 14,
                    )],
                  ),
                  child: Center(child: Text(_bravoActive ? '🎊' : '🎉',
                      style: const TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                const Text('⋯', style: TextStyle(fontSize: 20, color: Colors.black)),
                _showOpts,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMain(TextStyle orbitron, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT COL ──
          _buildLeftCol(),
          // ── CENTER ──
          Expanded(child: _buildCenter(orbitron)),
          // ── RIGHT COL ──
          _buildRightCol(),
        ],
      ),
    );
  }

  Widget _buildLeftCol() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _scoreBtn(1, 1),
              const SizedBox(height: 8),
              _scoreBtn(1, 2),
              const SizedBox(height: 8),
              _scoreBtn(1, 3),
            ],
          ),
          Row(
            children: [
              _shotResetBtn(14),
              const SizedBox(width: 5),
              _shotResetBtn(24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shotResetBtn(int val) {
    return GestureDetector(
      onTap: () => _setShotClock(val),
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Text('$val',
              style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildCenter(TextStyle orbitron) {
    return Column(
      children: [
        // ── TEAMS ROW ──
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamBlock(1, orbitron),
              // X separator
              SizedBox(
                width: 40, height: 50,
                child: CustomPaint(painter: _XPainter()),
              ),
              _buildTeamBlock(2, orbitron),
            ],
          ),
        ),
        // ── FOULS ROW ──
        _buildFoulsRow(orbitron),
        // ── SHOT/FOUL COUNTER ROW ──
        _buildCounterRow(orbitron),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildTeamBlock(int team, TextStyle orbitron) {
    final name = team == 1 ? _gs.tn1 : _gs.tn2;
    final score = team == 1 ? _gs.sc1 : _gs.sc2;

    return GestureDetector(
      onTap: () => _editTeamName(team),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name,
              style: GoogleFonts.rajdhani(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 2)),
          Text(
            '$score',
            style: orbitron.copyWith(
              fontSize: 72,
              color: const Color(0xFF00ee44),
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoulsRow(TextStyle orbitron) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _dotGroup(1),
        Row(
          children: [
            GestureDetector(
              onTap: () => _chgFoul(1, -1),
              child: const _TriangleArrow(left: true),
            ),
            const SizedBox(width: 4),
            Text('Fouls',
                style: GoogleFonts.rajdhani(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: const Color(0xFFcc0000), letterSpacing: 2)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _chgFoul(2, -1),
              child: const _TriangleArrow(left: false),
            ),
          ],
        ),
        _dotGroup(2),
      ],
    );
  }

  Widget _buildCounterRow(TextStyle orbitron) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _foulCtrl(() => _chgFoul(1, 1), '+'),
        const SizedBox(width: 20),
        Text('${_gs.f1}',
            style: orbitron.copyWith(fontSize: 30, color: const Color(0xFFffee00))),
        const SizedBox(width: 6),
        Text('x', style: GoogleFonts.rajdhani(
            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 6),
        Text('${_gs.f2}',
            style: orbitron.copyWith(fontSize: 30, color: const Color(0xFFff8800))),
        const SizedBox(width: 20),
        _foulCtrl(() => _chgFoul(2, 1), '+'),
      ],
    );
  }

  Widget _foulCtrl(VoidCallback onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(child: Text(label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black))),
      ),
    );
  }

  Widget _buildRightCol() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _scoreBtn(2, 1),
              const SizedBox(height: 8),
              _scoreBtn(2, 2),
              const SizedBox(height: 8),
              _scoreBtn(2, 3),
            ],
          ),
          Column(
            children: [
              _iconBtn(
                const Text('🔔', style: TextStyle(fontSize: 18)),
                () => _setShotClock(24),
              ),
              const SizedBox(height: 6),
              _iconBtn(
                const Text('↩', style: TextStyle(fontSize: 18, color: Colors.black)),
                _undoScore,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editTeamName(int team) {
    final ctrl = TextEditingController(text: team == 1 ? _gs.tn1 : _gs.tn2);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text('Edit ${team == 1 ? _gs.tn1 : _gs.tn2}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF333333),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                setState(() {
                  if (team == 1) _gs.tn1 = v; else _gs.tn2 = v;
                });
                _push(immediate: true);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── X Painter ──
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(3, 3), Offset(size.width - 3, size.height - 3), paint);
    canvas.drawLine(Offset(size.width - 3, 3), Offset(3, size.height - 3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Triangle arrow ──
class _TriangleArrow extends StatelessWidget {
  final bool left;
  const _TriangleArrow({required this.left});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 18),
      painter: _TrianglePainter(left: left),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final bool left;
  const _TrianglePainter({required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFcc0000);
    final path = Path();
    if (left) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height / 2);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height / 2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
