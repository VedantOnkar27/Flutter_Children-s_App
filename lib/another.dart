import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

// MAIN APP ENTRY POINT
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    const ProviderScope(
      child: LearnAndPlayApp(),
    ),
  );
}

// APP THEMES AND STYLING
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      secondary: Colors.amber,
      tertiary: Colors.redAccent,
      background: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Comic Sans MS',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        elevation: 8,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.indigo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      secondary: Colors.amber,
      tertiary: Colors.redAccent,
      background: const Color(0xFF303030),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF303030),
    fontFamily: 'Comic Sans MS',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 22, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        elevation: 8,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF424242),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

// MAIN APP WIDGET
class LearnAndPlayApp extends ConsumerWidget {
  const LearnAndPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Learn & Play',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// PROVIDERS FOR STATE MANAGEMENT
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, List<LeaderboardEntry>>((ref) {
  return LeaderboardNotifier();
});

final quizScoreProvider = StateProvider<int>((ref) => 0);

final currentQuizProvider = StateNotifierProvider<QuizNotifier, Quiz?>((ref) {
  return QuizNotifier();
});

// STATE NOTIFIERS
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile(
    name: 'Buddy',
    avatarIndex: 0,
    score: 0,
    badges: [],
    quizHistory: [],
  )) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Buddy';
    final avatarIndex = prefs.getInt('avatar_index') ?? 0;
    final score = prefs.getInt('user_score') ?? 0;
    final badges = prefs.getStringList('badges') ?? [];
    
    state = UserProfile(
      name: name,
      avatarIndex: avatarIndex,
      score: score,
      badges: badges,
      quizHistory: [],
    );
  }
  
  Future<void> updateProfile({String? name, int? avatarIndex}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) {
      prefs.setString('user_name', name);
    }
    
    if (avatarIndex != null) {
      prefs.setInt('avatar_index', avatarIndex);
    }
    
    state = UserProfile(
      name: name ?? state.name,
      avatarIndex: avatarIndex ?? state.avatarIndex,
      score: state.score,
      badges: state.badges,
      quizHistory: state.quizHistory,
    );
  }
  
  Future<void> addScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final newScore = state.score + points;
    prefs.setInt('user_score', newScore);
    
    state = UserProfile(
      name: state.name,
      avatarIndex: state.avatarIndex,
      score: newScore,
      badges: state.badges,
      quizHistory: state.quizHistory,
    );
  }
  
  Future<void> addBadge(String badge) async {
    if (state.badges.contains(badge)) return;
    
    final prefs = await SharedPreferences.getInstance();
    final updatedBadges = [...state.badges, badge];
    prefs.setStringList('badges', updatedBadges);
    
    state = UserProfile(
      name: state.name,
      avatarIndex: state.avatarIndex,
      score: state.score,
      badges: updatedBadges,
      quizHistory: state.quizHistory,
    );
  }
  
  Future<void> addQuizResult(QuizResult result) async {
    final updatedHistory = [...state.quizHistory, result];
    
    state = UserProfile(
      name: state.name,
      avatarIndex: state.avatarIndex,
      score: state.score,
      badges: state.badges,
      quizHistory: updatedHistory,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<List<LeaderboardEntry>> {
  LeaderboardNotifier() : super([]) {
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    // In a real app, this would load from Firebase or another backend
    state = [
      LeaderboardEntry(name: 'Super Sasha', score: 950, avatarIndex: 0),
      LeaderboardEntry(name: 'Brainy Ben', score: 875, avatarIndex: 1),
      LeaderboardEntry(name: 'Awesome Amy', score: 830, avatarIndex: 2),
      LeaderboardEntry(name: 'Clever Cameron', score: 790, avatarIndex: 3),
      LeaderboardEntry(name: 'Dazzling Dana', score: 720, avatarIndex: 4),
    ];
  }
  
  void addScore(String name, int score, int avatarIndex) {
    final existingEntryIndex = state.indexWhere((entry) => entry.name == name);
    
    if (existingEntryIndex >= 0) {
      final existingEntry = state[existingEntryIndex];
      if (score > existingEntry.score) {
        final updatedEntry = LeaderboardEntry(
          name: name,
          score: score,
          avatarIndex: avatarIndex,
        );
        
        final newList = [...state];
        newList[existingEntryIndex] = updatedEntry;
        newList.sort((a, b) => b.score.compareTo(a.score));
        state = newList;
      }
    } else {
      final newEntry = LeaderboardEntry(
        name: name,
        score: score,
        avatarIndex: avatarIndex,
      );
      
      final newList = [...state, newEntry];
      newList.sort((a, b) => b.score.compareTo(a.score));
      state = newList;
    }
  }
}

class QuizNotifier extends StateNotifier<Quiz?> {
  QuizNotifier() : super(null);
  
  void startAlphabetQuiz() {
    state = Quiz(
      type: QuizType.alphabet,
      questions: _generateAlphabetQuestions(),
      currentQuestionIndex: 0,
      score: 0,
    );
  }
  
  void startNumberQuiz() {
    state = Quiz(
      type: QuizType.number,
      questions: _generateNumberQuestions(),
      currentQuestionIndex: 0,
      score: 0,
    );
  }
  
  List<Question> _generateAlphabetQuestions() {
    final questions = <Question>[];
    final allLetters = List.generate(26, (index) => String.fromCharCode(65 + index));
    final random = Random();
    
    // Generate 5 random questions
    for (int i = 0; i < 5; i++) {
      final correctIndex = random.nextInt(26);
      final correctAnswer = allLetters[correctIndex];
      
      // Create 3 wrong options
      final options = <String>[];
      options.add(correctAnswer);
      
      while (options.length < 4) {
        final randomLetter = allLetters[random.nextInt(26)];
        if (!options.contains(randomLetter)) {
          options.add(randomLetter);
        }
      }
      
      options.shuffle();
      
      questions.add(Question(
        prompt: 'Which letter is this?',
        content: correctAnswer,
        options: options,
        correctAnswer: correctAnswer,
      ));
    }
    
    return questions;
  }
  
  List<Question> _generateNumberQuestions() {
    final questions = <Question>[];
    final allNumbers = List.generate(10, (index) => index.toString());
    final random = Random();
    
    // Generate 5 random questions
    for (int i = 0; i < 5; i++) {
      final correctIndex = random.nextInt(10);
      final correctAnswer = allNumbers[correctIndex];
      
      // Create 3 wrong options
      final options = <String>[];
      options.add(correctAnswer);
      
      while (options.length < 4) {
        final randomNumber = allNumbers[random.nextInt(10)];
        if (!options.contains(randomNumber)) {
          options.add(randomNumber);
        }
      }
      
      options.shuffle();
      
      questions.add(Question(
        prompt: 'Which number is this?',
        content: correctAnswer,
        options: options,
        correctAnswer: correctAnswer,
      ));
    }
    
    return questions;
  }
  
  void answerQuestion(String answer) {
    if (state == null) return;
    
    final currentQuestion = state!.questions[state!.currentQuestionIndex];
    final isCorrect = currentQuestion.correctAnswer == answer;
    final newScore = isCorrect ? state!.score + 20 : state!.score;
    
    if (state!.currentQuestionIndex < state!.questions.length - 1) {
      state = Quiz(
        type: state!.type,
        questions: state!.questions,
        currentQuestionIndex: state!.currentQuestionIndex + 1,
        score: newScore,
      );
    } else {
      // Quiz completed
      state = Quiz(
        type: state!.type,
        questions: state!.questions,
        currentQuestionIndex: state!.currentQuestionIndex,
        score: newScore,
        isCompleted: true,
      );
    }
  }
  
  void resetQuiz() {
    state = null;
  }
}

// DATA MODELS
class UserProfile {
  final String name;
  final int avatarIndex;
  final int score;
  final List<String> badges;
  final List<QuizResult> quizHistory;
  
  UserProfile({
    required this.name,
    required this.avatarIndex,
    required this.score,
    required this.badges,
    required this.quizHistory,
  });
}

class QuizResult {
  final QuizType type;
  final int score;
  final DateTime dateTime;
  
  QuizResult({
    required this.type,
    required this.score,
    required this.dateTime,
  });
}

enum QuizType {
  alphabet,
  number,
}

class Quiz {
  final QuizType type;
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final bool isCompleted;
  
  Quiz({
    required this.type,
    required this.questions,
    required this.currentQuestionIndex,
    required this.score,
    this.isCompleted = false,
  });
}

class Question {
  final String prompt;
  final String content;
  final List<String> options;
  final String correctAnswer;
  
  Question({
    required this.prompt,
    required this.content,
    required this.options,
    required this.correctAnswer,
  });
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int avatarIndex;
  
  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.avatarIndex,
  });
}

class LessonItem {
  final String content;
  final String audioAsset;
  final String animationAsset;
  final String description;
  
  LessonItem({
    required this.content,
    required this.audioAsset,
    required this.animationAsset,
    required this.description,
  });
}

// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _animationController.forward();
    
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const AppLogo(size: 200),
              ),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  'Learn & Play',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// REUSABLE APP LOGO WIDGET
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'A 1',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// HOME SCREEN WITH TAB CONTROLLER
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & Play'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  ref.read(themeModeProvider) == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Practice'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaders'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            PracticeScreen(),
            QuizScreen(),
            LeaderboardScreen(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }
}

// PRACTICE/LESSONS SCREEN
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: TabBar(
              tabs: const [
                Tab(text: 'Alphabet'),
                Tab(text: 'Numbers'),
              ],
              labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 4,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Alphabets grid
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 26,
                  itemBuilder: (context, index) {
                    final letter = String.fromCharCode(65 + index);
                    return LessonCard(
                      content: letter,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonDetailScreen(
                              lessonItem: LessonItem(
                                content: letter,
                                audioAsset: 'assets/audio/letters/$letter.mp3',
                                animationAsset: 'assets/animations/letters/$letter.json',
                                description: '$letter is for...',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // Numbers grid
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return LessonCard(
                      content: index.toString(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonDetailScreen(
                              lessonItem: LessonItem(
                                content: index.toString(),
                                audioAsset: 'assets/audio/numbers/$index.mp3',
                                animationAsset: 'assets/animations/numbers/$index.json',
                                description: 'Count to $index',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final String content;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
                Theme.of(context).colorScheme.primary,
              ],
            ),
          ),
          child: Center(
            child: Text(
              content,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonDetailScreen extends ConsumerStatefulWidget {
  final LessonItem lessonItem;

  const LessonDetailScreen({
    super.key,
    required this.lessonItem,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void _playAnimation() {
    setState(() {
      isAnimating = true;
    });
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        isAnimating = false;
      });
    });
  }

  void _playSound() {
    // In a real app, use the actual asset: audioPlayer.play(AssetSource(widget.lessonItem.audioAsset));
    // For now, let's simulate playing a sound
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing sound for ${widget.lessonItem.content}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learn ${widget.lessonItem.content}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character display with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: isAnimating
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.lessonItem.content,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 80,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.lessonItem.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 60),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _playAnimation,
                  icon: const Icon(Icons.draw),
                  label: const Text('Show Strokes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _playSound,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Play Sound'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// QUIZ SCREEN
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentQuiz = ref.watch(currentQuizProvider);
    
    // If there's no active quiz, show quiz selection
    if (currentQuiz == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Lottie(
              repeat: true,
              width: 200,
              height: 200,
              animate: true, composition: null,
              // In real app, use: asset: 'assets/animations/quiz_intro.json'
            ),
            const SizedBox(height: 32),
            Text(
              'Choose a Quiz!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.abc),
              label: const Text('Alphabet Quiz'),
              onPressed: () {
                ref.read(currentQuizProvider.notifier).startAlphabetQuiz();
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.numbers),
              label: const Text('Number Quiz'),
              onPressed: () {
                ref.read(currentQuizProvider.notifier).startNumberQuiz();
              },
            ),
          ],
        ),
      );
    }
    
    // Quiz is completed, show results
    if (currentQuiz.isCompleted) {
      return QuizResultScreen(quiz: currentQuiz);
    }
    
    // Show active quiz
    final currentQuestion = currentQuiz.questions[currentQuiz.currentQuestionIndex];
    
    return Scaffold(
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentQuiz.currentQuestionIndex + 1) / currentQuiz.questions.length,
            backgroundColor: Colors.grey.shade200,
            color: Theme.of(context).colorScheme.secondary,
            minHeight: 10,
          ),
          
          // Question counter and score
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuiz.currentQuestionIndex + 1}/${currentQuiz.questions.length}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Score: ${currentQuiz.score}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Question content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentQuestion.prompt,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 40),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        currentQuestion.content,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Answer options
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final option = currentQuestion.options[index];
                return ElevatedButton(
                  onPressed: () {
                    ref.read(currentQuizProvider.notifier).answerQuestion(option);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultScreen extends ConsumerWidget {
  final Quiz quiz;
  
  const QuizResultScreen({
    super.key,
    required this.quiz,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    
    // Add score to user profile
    Future.microtask(() {
      ref.read(userProfileProvider.notifier).addScore(quiz.score);
      
      // Also add to leaderboard
      ref.read(leaderboardProvider.notifier).addScore(
        profile.name,
        profile.score + quiz.score,
        profile.avatarIndex,
      );
      
      // Add quiz result to history
      ref.read(userProfileProvider.notifier).addQuizResult(
        QuizResult(
          type: quiz.type,
          score: quiz.score,
          dateTime: DateTime.now(),
        ),
      );
      
      // Award badge if perfect score
      if (quiz.score == quiz.questions.length * 20) {
        final badgeName = quiz.type == QuizType.alphabet ? 'Alphabet Master' : 'Number Pro';
        ref.read(userProfileProvider.notifier).addBadge(badgeName);
      }
    });
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated confetti or celebration
            const SizedBox(height: 20),
            
            // Results title
            Text(
              'Quiz Complete!',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20),
            
            // Score display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '${quiz.score}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Status message
            Text(
              _getResultMessage(quiz.score, quiz.questions.length * 20),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  onPressed: () {
                    if (quiz.type == QuizType.alphabet) {
                      ref.read(currentQuizProvider.notifier).startAlphabetQuiz();
                    } else {
                      ref.read(currentQuizProvider.notifier).startNumberQuiz();
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  onPressed: () {
                    ref.read(currentQuizProvider.notifier).resetQuiz();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getResultMessage(int score, int maxScore) {
    final percentage = score / maxScore * 100;
    
    if (percentage >= 90) {
      return 'Fantastic! You\'re a superstar!';
    } else if (percentage >= 70) {
      return 'Great job! You\'re doing amazing!';
    } else if (percentage >= 50) {
      return 'Good effort! Keep practicing!';
    } else {
      return 'Nice try! Let\'s practice more!';
    }
  }
}

// LEADERBOARD SCREEN
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'Top Players',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final isTopThree = index < 3;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isTopThree ? 8 : 4,
                  color: isTopThree 
                      ? Theme.of(context).colorScheme.secondaryContainer 
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAvatarColor(entry.avatarIndex),
                      child: Text(
                        entry.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.name,
                      style: TextStyle(
                        fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('Score: ${entry.score}'),
                    trailing: isTopThree
                        ? Icon(
                            Icons.emoji_events,
                            color: _getTrophyColor(index),
                            size: 32,
                          )
                        : Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    
    return colors[index % colors.length];
  }
  
  Color _getTrophyColor(int position) {
    switch (position) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey.shade300; // Silver
      case 2:
        return Colors.brown.shade300; // Bronze
      default:
        return Colors.grey;
    }
  }
}

// PROFILE SCREEN
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // Profile avatar
              GestureDetector(
                onTap: () => _showAvatarSelector(context, ref),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: _getAvatarColor(profile.avatarIndex),
                      child: Text(
                        profile.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 52,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              // Score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Total Score: ${profile.score}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Badges section
              const Text(
                'Badges Earned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Badge grid
              profile.badges.isEmpty
                  ? const Text(
                      'Complete quizzes to earn badges!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: profile.badges
                          .map((badge) => _buildBadge(context, badge))
                          .toList(),
                    ),
              const SizedBox(height: 32),
              
              // Progress section
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Progress bars
              _buildProgressItem(
                context,
                'Alphabet',
                0.7, // Placeholder progress value
                isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              _buildProgressItem(
                context,
                'Numbers',
                0.5, // Placeholder progress value
                isDarkMode ? Colors.teal.shade300 : Colors.teal,
              ),
              const SizedBox(height: 32),
              
              // Settings button
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                onPressed: () => _showParentPINDialog(context),
              ),
              const SizedBox(height: 16),
              
              // Reset progress button
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Progress'),
                onPressed: () => _showParentPINDialog(context, isReset: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadge(BuildContext context, String badge) {
    IconData iconData;
    Color color;
    
    if (badge.contains('Alphabet')) {
      iconData = Icons.abc;
      color = Colors.purple;
    } else if (badge.contains('Number')) {
      iconData = Icons.numbers;
      color = Colors.teal;
    } else {
      iconData = Icons.emoji_events;
      color = Colors.amber;
    }
    
    return Tooltip(
      message: badge,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              badge.split(' ')[0],
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressItem(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          color: color,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 4),
        Text('${(value * 100).toInt()}% Complete'),
      ],
    );
  }
  
  void _showAvatarSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Avatar'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  ref.read(userProfileProvider.notifier).updateProfile(
                    avatarIndex: index,
                  );
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  backgroundColor: _getAvatarColor(index),
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showParentPINDialog(BuildContext context, {bool isReset = false}) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReset ? 'Parent PIN Required' : 'Parent Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isReset
                  ? 'Enter parent PIN to reset progress:'
                  : 'Enter parent PIN to access settings:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PIN',
                counterText: '',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // For demo, PIN is always "1234"
              if (pinController.text == '1234') {
                Navigator.pop(context);
                
                if (isReset) {
                  _showResetConfirmation(context);
                } else {
                  _showSettingsDialog(context);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parent Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Sound Effects'),
              value: true,
              onChanged: null, // Placeholder
            ),
            SwitchListTile(
              title: Text('Background Music'),
              value: false,
              onChanged: null, // Placeholder 
            ),
            SwitchListTile(
              title: Text('Daily Reminder'),
              value: true,
              onChanged: null, // Placeholder
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will reset all progress, scores, and badges. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Reset logic would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress has been reset'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset All Progress'),
          ),
        ],
      ),
    );
  }
  
  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return colors[index % colors.length];
  }
}