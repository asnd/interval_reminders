import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Notification initialization would go here in a real deployment
  // await NotificationService.initialize(); 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: const IntervalApp(),
    ),
  );
}

class IntervalApp extends StatelessWidget {
  const IntervalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interval Reminders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Indigo
          secondary: const Color(0xFFFFC107), // Amber
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

enum TimerState { idle, running, paused }
enum IntervalType { work, rest }

class TimerService extends ChangeNotifier {
  // Configuration (minutes)
  int _workDuration = 45; 
  int _restDuration = 15;

  // State
  TimerState _state = TimerState.idle;
  IntervalType _currentType = IntervalType.work;
  int _secondsRemaining = 45 * 60;
  Timer? _timer;

  TimerService() {
    _loadSettings();
  }

  // Getters
  int get workDuration => _workDuration;
  int get restDuration => _restDuration;
  TimerState get state => _state;
  IntervalType get currentType => _currentType;
  int get secondsRemaining => _secondsRemaining;
  
  double get progress {
    int total = (_currentType == IntervalType.work ? _workDuration : _restDuration) * 60;
    if (total == 0) return 0;
    return 1.0 - (_secondsRemaining / total);
  }

  String get timerString {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Actions
  void setWorkDuration(int minutes) {
    _workDuration = minutes;
    if (_state == TimerState.idle && _currentType == IntervalType.work) {
      _resetTimer();
    }
    _saveSettings();
    notifyListeners();
  }

  void setRestDuration(int minutes) {
    _restDuration = minutes;
    if (_state == TimerState.idle && _currentType == IntervalType.rest) {
      _resetTimer();
    }
    _saveSettings();
    notifyListeners();
  }

  void start() {
    if (_state == TimerState.running) return;
    _state = TimerState.running;
    notifyListeners();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
      } else {
        _switchInterval();
      }
      notifyListeners();
    });
  }

  void pause() {
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _state = TimerState.idle;
    _currentType = IntervalType.work;
    _resetTimer();
    notifyListeners();
  }

  void skip() {
    _switchInterval();
  }

  void _switchInterval() {
    _timer?.cancel();
    
    // Toggle type
    _currentType = _currentType == IntervalType.work ? IntervalType.rest : IntervalType.work;
    
    // Send Notification (Simulated)
    print("Interval Finished! Switching to ${_currentType.name.toUpperCase()}");
    
    _resetTimer();
    
    // Auto-start next interval? Usually safer to wait for user, but for reminders we might want continuous.
    // Let's pause and notify for now.
    _state = TimerState.paused; // Or running if we want continuous
    // For this app, let's keep running to ensure we push the user.
    start(); 
  }

  void _resetTimer() {
    _secondsRemaining = (_currentType == IntervalType.work ? _workDuration : _restDuration) * 60;
  }

  // Persistence
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _workDuration = prefs.getInt('workDuration') ?? 45;
    _restDuration = prefs.getInt('restDuration') ?? 15;
    if (_state == TimerState.idle) {
      _resetTimer();
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workDuration', _workDuration);
    await prefs.setInt('restDuration', _restDuration);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerService>();
    final isWork = timer.currentType == IntervalType.work;
    final color = isWork ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interval Reminders'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: timer.progress,
                    strokeWidth: 20,
                    backgroundColor: color.withOpacity(0.2),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isWork ? "FOCUS" : "REST",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      timer.timerString,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timer.state != TimerState.running)
                  FloatingActionButton.large(
                    onPressed: timer.start,
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.play_arrow),
                  )
                else
                  FloatingActionButton.large(
                    onPressed: timer.pause,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: const Icon(Icons.pause),
                  ),
                  
                const SizedBox(width: 20),
                
                FloatingActionButton(
                  onPressed: timer.reset,
                  mini: true,
                  heroTag: "reset",
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.refresh),
                ),
                
                 const SizedBox(width: 20),

                 FloatingActionButton(
                  onPressed: timer.skip,
                  mini: true,
                  heroTag: "skip",
                   backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.skip_next),
                ),
              ],
            ),

            const Spacer(),

            // Settings Sheet
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Interval Settings", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  
                  _buildSlider(
                    context, 
                    label: "Action (min)", 
                    value: timer.workDuration, 
                    min: 10, max: 120, 
                    onChanged: (v) => timer.setWorkDuration(v.toInt())
                  ),
                  
                  const SizedBox(height: 10),
                  
                  _buildSlider(
                    context, 
                    label: "Rest (min)", 
                    value: timer.restDuration, 
                    min: 5, max: 180, 
                    onChanged: (v) => timer.setRestDuration(v.toInt())
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, {
    required String label, 
    required int value, 
    required double min, 
    required double max, 
    required ValueChanged<double> onChanged
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
