class GameState {
  int sc1;
  int sc2;
  int f1;
  int f2;
  int dt1;
  int dt2;
  int qtr;
  String tn1;
  String tn2;
  int mainSec;
  int shot;
  int shotMs;
  bool mainRunning;
  bool shotRunning;

  GameState({
    this.sc1 = 0,
    this.sc2 = 0,
    this.f1 = 0,
    this.f2 = 0,
    this.dt1 = 0,
    this.dt2 = 0,
    this.qtr = 1,
    this.tn1 = 'Team 1',
    this.tn2 = 'Team 2',
    this.mainSec = 600,
    this.shot = 24,
    this.shotMs = 0,
    this.mainRunning = false,
    this.shotRunning = false,
  });

  Map<String, dynamic> toMap() => {
        'sc1': sc1,
        'sc2': sc2,
        'f1': f1,
        'f2': f2,
        'dt1': dt1,
        'dt2': dt2,
        'qtr': qtr,
        'tn1': tn1,
        'tn2': tn2,
        'mainSec': mainSec,
        'shot': shot,
        'shotMs': shotMs,
        'mainRunning': mainRunning,
        'shotRunning': shotRunning,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };

  static const List<String> quarterNames = ['1st', '2nd', '3rd', '4th'];
  String get quarterName => quarterNames[(qtr - 1) % 4];

  String get mainClockDisplay {
    final m = mainSec ~/ 60;
    final s = mainSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get shotClockDisplay {
    final d = (shotMs ~/ 100);
    return '${shot.toString().padLeft(2, '0')}.$d';
  }
}
