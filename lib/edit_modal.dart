import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_state.dart';

class EditModal extends StatefulWidget {
  final GameState gs;
  final VoidCallback onChanged;
  final VoidCallback onStopAll;

  const EditModal({
    super.key,
    required this.gs,
    required this.onChanged,
    required this.onStopAll,
  });

  @override
  State<EditModal> createState() => _EditModalState();
}

class _EditModalState extends State<EditModal> {
  late TextEditingController _en1, _en2;

  @override
  void initState() {
    super.initState();
    _en1 = TextEditingController(text: widget.gs.tn1);
    _en2 = TextEditingController(text: widget.gs.tn2);
  }

  @override
  void dispose() {
    _en1.dispose();
    _en2.dispose();
    super.dispose();
  }

  void _notify() {
    setState(() {});
    widget.onChanged();
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFaaaaaa), fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _stepRow(String label, int value, VoidCallback onMinus, VoidCallback onPlus,
      {Color valColor = const Color(0xFF00ff88)}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Row(
          children: [
            _stpBtn('-', onMinus, Colors.red),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w900, color: valColor)),
            ),
            const SizedBox(width: 8),
            _stpBtn('+', onPlus, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _stpBtn(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final orbitron = GoogleFonts.orbitron(fontWeight: FontWeight.w900);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0a0a0a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
          ),
          // Title
          Text('✏️ EDIT MODE',
              style: orbitron.copyWith(fontSize: 18, color: const Color(0xFFffcc00), letterSpacing: 2)),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Main Clock ──
                  _section('⏱ Main Clock', [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timeUnit('MIN', gs.mainSec ~/ 60,
                            () { setState(() { gs.mainSec = ((gs.mainSec ~/ 60 - 1).clamp(0, 59)) * 60 + gs.mainSec % 60; }); widget.onChanged(); },
                            () { setState(() { gs.mainSec = ((gs.mainSec ~/ 60 + 1).clamp(0, 59)) * 60 + gs.mainSec % 60; }); widget.onChanged(); },
                            orbitron),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(':', style: orbitron.copyWith(fontSize: 26, color: Colors.red)),
                        ),
                        _timeUnit('SEC', gs.mainSec % 60,
                            () { setState(() { gs.mainSec = (gs.mainSec ~/ 60) * 60 + (gs.mainSec % 60 - 1).clamp(0, 59); }); widget.onChanged(); },
                            () { setState(() { gs.mainSec = (gs.mainSec ~/ 60) * 60 + (gs.mainSec % 60 + 1).clamp(0, 59); }); widget.onChanged(); },
                            orbitron),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Shot Clock ──
                  _section('🟡 Shot Clock (sec)', [
                    _stepRow('Shot Clock', gs.shot,
                        () { setState(() { gs.shot = (gs.shot - 1).clamp(0, 60); gs.shotMs = 0; }); widget.onChanged(); },
                        () { setState(() { gs.shot = (gs.shot + 1).clamp(0, 60); gs.shotMs = 0; }); widget.onChanged(); }),
                  ]),
                  const SizedBox(height: 12),

                  // ── Quarter ──
                  _section('🏀 Quarter', [
                    Row(
                      children: List.generate(4, (i) {
                        final active = gs.qtr == i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () { setState(() => gs.qtr = i + 1); widget.onChanged(); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFF2a2200) : const Color(0xFF111111),
                                border: Border.all(
                                    color: active ? const Color(0xFFffcc00) : const Color(0xFF444444)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(GameState.quarterNames[i],
                                  style: TextStyle(
                                      color: active ? const Color(0xFFffcc00) : const Color(0xFF888888),
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                        );
                      }),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── Team 1 ──
                  _section('🟡 Team 1', [
                    _nameRow(1, _en1),
                    const SizedBox(height: 10),
                    _stepRow('Score', gs.sc1,
                        () { setState(() => gs.sc1 = (gs.sc1 - 1).clamp(0, 999)); widget.onChanged(); },
                        () { setState(() => gs.sc1++); widget.onChanged(); },
                        valColor: const Color(0xFFffee00)),
                    const SizedBox(height: 8),
                    _stepRow('Fouls', gs.f1,
                        () { setState(() => gs.f1 = (gs.f1 - 1).clamp(0, 99)); widget.onChanged(); },
                        () { setState(() => gs.f1++); widget.onChanged(); }),
                  ]),
                  const SizedBox(height: 12),

                  // ── Team 2 ──
                  _section('🟠 Team 2', [
                    _nameRow(2, _en2),
                    const SizedBox(height: 10),
                    _stepRow('Score', gs.sc2,
                        () { setState(() => gs.sc2 = (gs.sc2 - 1).clamp(0, 999)); widget.onChanged(); },
                        () { setState(() => gs.sc2++); widget.onChanged(); },
                        valColor: const Color(0xFFffee00)),
                    const SizedBox(height: 8),
                    _stepRow('Fouls', gs.f2,
                        () { setState(() => gs.f2 = (gs.f2 - 1).clamp(0, 99)); widget.onChanged(); },
                        () { setState(() => gs.f2++); widget.onChanged(); }),
                  ]),
                  const SizedBox(height: 16),

                  // ── Done button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('✅ Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeUnit(String label, int value, VoidCallback onMinus, VoidCallback onPlus, TextStyle orbitron) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11, letterSpacing: 1)),
        _stpBtn('−', onMinus, Colors.red),
        Container(
          width: 56, height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(value.toString().padLeft(2, '0'),
                style: orbitron.copyWith(fontSize: 26, color: Colors.red)),
          ),
        ),
        _stpBtn('+', onPlus, Colors.green),
      ],
    );
  }

  Widget _nameRow(int team, TextEditingController ctrl) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF333333),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF666666))),
              hintText: 'Team $team',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            final v = ctrl.text.trim();
            if (v.isNotEmpty) {
              setState(() {
                if (team == 1) widget.gs.tn1 = v; else widget.gs.tn2 = v;
              });
              widget.onChanged();
            }
          },
          child: Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(color: Color(0xFF2980b9), shape: BoxShape.circle),
            child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 18))),
          ),
        ),
      ],
    );
  }
}
