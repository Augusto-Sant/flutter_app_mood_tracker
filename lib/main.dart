import 'package:flutter/material.dart';
import 'dart:async';
import 'package:window_size/window_size.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    setWindowTitle('Mood Tracker');
    setWindowMinSize(const Size(400, 800));
    setWindowMaxSize(const Size(400, 900));
  }

  runApp(const MoodTrackerApp());
}

// ============= APP PRINCIPAL =============
class MoodTrackerApp extends StatefulWidget {
  const MoodTrackerApp({Key? key}) : super(key: key);

  @override
  State<MoodTrackerApp> createState() => _MoodTrackerAppState();
}

class _MoodTrackerAppState extends State<MoodTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final String? savedTheme = _prefs.getString('theme_mode');
    setState(() {
      _themeMode = savedTheme == 'dark'
          ? ThemeMode.dark
          : savedTheme == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  Future<void> _toggleTheme() async {
    ThemeMode newTheme;
    if (_themeMode == ThemeMode.dark) {
      newTheme = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      newTheme = ThemeMode.system;
    } else {
      newTheme = ThemeMode.dark;
    }

    setState(() {
      _themeMode = newTheme;
    });

    await _prefs.setString(
      'theme_mode',
      newTheme == ThemeMode.dark
          ? 'dark'
          : newTheme == ThemeMode.light
              ? 'light'
              : 'system',
    );
  }

  IconData _getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.dark:
        return Icons.light_mode;
      case ThemeMode.light:
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFFF6B9D),
          elevation: 0,
        ),
        cardColor: Colors.white,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFFFF6B9D),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        shadowColor: Colors.grey,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF333333)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFFF6B9D),
          elevation: 0,
        ),
        cardColor: const Color(0xFF1E1E1E),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFFFF6B9D),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFF6B9D)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
        ),
        shadowColor: Colors.black26,
      ),
      home: SplashScreen(
        onThemeToggle: _toggleTheme,
        themeMode: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============= SPLASHSCREEN =============
class SplashScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  const SplashScreen({
    Key? key,
    required this.onThemeToggle,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            onThemeToggle: widget.onThemeToggle,
            themeMode: widget.themeMode,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      size: 60,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Mood Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B9D),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Como você está se sentindo hoje?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF8FAB),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============= HOME PAGE =============
class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  const HomePage({
    Key? key,
    required this.onThemeToggle,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<MoodEntry> _moodHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? moodData = prefs.getString('mood_history');
    
    if (moodData != null) {
      final List<dynamic> decoded = jsonDecode(moodData);
      setState(() {
        _moodHistory.addAll(decoded.map((item) => MoodEntry.fromJson(item)).toList());
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMoodHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_moodHistory.map((e) => e.toJson()).toList());
    await prefs.setString('mood_history', encoded);
  }

  void _addMood(IconData icon, String label, int value, Color color) {
    setState(() {
      _moodHistory.add(MoodEntry(
        icon: icon,
        label: label,
        value: value,
        color: color,
        date: DateTime.now(),
      ));
    });

    _saveMoodHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Humor registrado: $label'),
        backgroundColor: const Color(0xFFFF6B9D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B9D),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Meu Humor Hoje',
          style: TextStyle(
            color: Color(0xFFFF6B9D),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // BOTÃO DE TEMA
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : widget.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
              color: const Color(0xFFFF6B9D),
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Alternar tema',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFFF6B9D)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsPage(moodHistory: _moodHistory),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFFF6B9D)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPage(
                    moodHistory: _moodHistory,
                    onDelete: (index) {
                      setState(() {
                        _moodHistory.removeAt(index);
                      });
                      _saveMoodHistory();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Como você está se sentindo?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildMoodCard(
                  Icons.sentiment_very_satisfied,
                  'Feliz',
                  5,
                  Colors.yellow.shade300,
                ),
                _buildMoodCard(
                  Icons.sentiment_satisfied,
                  'Calmo',
                  4,
                  Colors.green.shade300,
                ),
                _buildMoodCard(
                  Icons.sentiment_neutral,
                  'Neutro',
                  3,
                  Colors.grey.shade300,
                ),
                _buildMoodCard(
                  Icons.sentiment_dissatisfied,
                  'Triste',
                  2,
                  Colors.blue.shade300,
                ),
                _buildMoodCard(
                  Icons.sentiment_very_dissatisfied,
                  'Ansioso',
                  2,
                  Colors.orange.shade300,
                ),
                _buildMoodCard(
                  Icons.mood_bad,
                  'Irritado',
                  1,
                  Colors.red.shade300,
                ),
              ],
            ),
          ),
          if (_moodHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Últimos registros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _moodHistory.length > 7 ? 7 : _moodHistory.length,
                      itemBuilder: (context, index) {
                        final mood = _moodHistory[_moodHistory.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            mood.icon,
                            size: 30,
                            color: mood.color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(IconData icon, String label, int value, Color color) {
    return GestureDetector(
      onTap: () => _addMood(icon, label, value, color),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 45,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= HISTORY PAGE =============
class HistoryPage extends StatelessWidget {
  final List<MoodEntry> moodHistory;
  final Function(int) onDelete;

  const HistoryPage({
    Key? key,
    required this.moodHistory,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B9D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histórico',
          style: TextStyle(
            color: Color(0xFFFF6B9D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: moodHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nenhum registro ainda',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: moodHistory.length,
              itemBuilder: (context, index) {
                final reversedIndex = moodHistory.length - 1 - index;
                final mood = moodHistory[reversedIndex];
                final dateStr = DateFormat('dd/MM/yyyy - HH:mm').format(mood.date);

                return Dismissible(
                  key: Key(mood.date.toString()),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    onDelete(reversedIndex);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro removido'),
                        backgroundColor: Color(0xFFFF6B9D),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: mood.color.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: mood.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            mood.icon,
                            color: mood.color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mood.label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_left,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============= STATS PAGE =============
class StatsPage extends StatelessWidget {
  final List<MoodEntry> moodHistory;

  const StatsPage({Key? key, required this.moodHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B9D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Estatísticas',
          style: TextStyle(
            color: Color(0xFFFF6B9D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: moodHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nenhum registro ainda',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Comece registrando seu humor!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    context: context,
                    icon: Icons.trending_up,
                    title: 'Média de Humor',
                    value: stats['average']!.toStringAsFixed(1),
                    subtitle: 'De 1 a 5',
                    color: Colors.purple.shade300,
                  ),
                  const SizedBox(height: 15),
                  _buildStatCard(
                    context: context,
                    icon: Icons.calendar_today,
                    title: 'Total de Registros',
                    value: moodHistory.length.toString(),
                    subtitle: 'Dias registrados',
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(height: 15),
                  _buildMostCommonCard(context: context, entry: stats['mostCommonEntry'] as MoodEntry),
                  const SizedBox(height: 30),
                  const Text(
                    'Distribuição dos Humores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._buildMoodDistribution(context: context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostCommonCard({required BuildContext context, required MoodEntry entry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: entry.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(entry.icon, color: entry.color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Humor Mais Comum',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: entry.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMoodDistribution({required BuildContext context}) {
    final distribution = <String, MoodData>{};

    for (var entry in moodHistory) {
      final key = entry.label;
      if (distribution.containsKey(key)) {
        distribution[key]!.count++;
      } else {
        distribution[key] = MoodData(
          icon: entry.icon,
          color: entry.color,
          label: entry.label,
          count: 1,
        );
      }
    }

    return distribution.values.map((data) {
      final percentage = (data.count / moodHistory.length * 100).toStringAsFixed(0);
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              data.icon,
              size: 35,
              color: data.color,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: data.count / moodHistory.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(data.color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Map<String, dynamic> _calculateStats() {
    if (moodHistory.isEmpty) {
      return {'average': 0.0, 'mostCommonEntry': null};
    }

    double sum = 0;
    final Map<String, int> counts = {};

    for (var entry in moodHistory) {
      sum += entry.value;
      counts[entry.label] = (counts[entry.label] ?? 0) + 1;
    }

    final mostCommonLabel = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final mostCommonEntry = moodHistory.firstWhere((e) => e.label == mostCommonLabel);

    return {
      'average': sum / moodHistory.length,
      'mostCommonEntry': mostCommonEntry,
    };
  }
}

// ============= DTOS =============
class MoodEntry {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final DateTime date;

  MoodEntry({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'iconCode': icon.codePoint,
      'label': label,
      'value': value,
      'colorValue': color.value,
      'date': date.toIso8601String(),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
      label: json['label'],
      value: json['value'],
      color: Color(json['colorValue']),
      date: DateTime.parse(json['date']),
    );
  }
}

class MoodData {
  final IconData icon;
  final Color color;
  final String label;
  int count;
  MoodData({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });
}