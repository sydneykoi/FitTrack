import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MyApp());

// ---------- MAIN APP ----------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'FitTrack',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/main': (context) => const MainScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/editProfile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}

// ---------- APP STATE ----------
class AppState extends ChangeNotifier {
  // Auth State
  bool isLoggedIn = false;
  bool isOnboardingComplete = false;

  // User Profile
  String userName = 'Sam Carter';
  String userEmail = 'sam.carter@email.com';
  int age = 28;
  int height = 175;
  int weight = 72;
  String activityLevel = 'Active';
  String fitnessGoal = 'Lose Weight';
  int stepGoal = 10000;
  String unitSystem = 'kg';

  // Notification Settings
  bool dailyReminders = true;
  bool weeklyReports = true;
  bool achievementAlerts = true;
  bool workoutTips = false;

  // Workout State
  bool isWorkoutActive = false;
  bool isPaused = false;
  String activityType = 'Walk';
  Duration elapsedTime = Duration.zero;
  double distance = 0.0;
  double pace = 0.0;
  int calories = 0;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  // Workout History
  final List<Map<String, dynamic>> workoutHistory = [];

  // ---------- DYNAMIC STATS DATA ----------
  int todaySteps = 0;
  int todayCalories = 0;
  int activeMinutes = 0;
  List<double> weeklySteps = [];
  List<double> monthlySteps = [];
  bool _isGeneratingData = false;

  // ---------- GENERATE REALISTIC DATA ----------
  void generateData() {
    if (_isGeneratingData) return;
    _isGeneratingData = true;

    final random = Random();

    todaySteps = 3000 + random.nextInt(12000);
    todayCalories = (todaySteps * 0.04).round();
    activeMinutes = 10 + random.nextInt(80);

    weeklySteps = List.generate(7, (index) {
      double base = 3000 + random.nextInt(10000).toDouble();
      double variation = (random.nextDouble() - 0.5) * 4000;
      double daySteps = base + variation;
      if (index == 5 || index == 6) {
        daySteps += 2000;
      }
      return daySteps.clamp(1000.0, 20000.0);
    });

    monthlySteps = List.generate(30, (index) {
      double base = 2500 + random.nextInt(11000).toDouble();
      int dayOfWeek = index % 7;
      double weekendBonus = (dayOfWeek == 5 || dayOfWeek == 6) ? 2500 : 0;
      double variation = (random.nextDouble() - 0.5) * 5000;
      double daySteps = base + weekendBonus + variation;
      double trend = index * 50;
      return (daySteps + trend).clamp(1000.0, 22000.0);
    });

    _isGeneratingData = false;
    notifyListeners();
  }

  void refreshData() {
    generateData();
  }

  // ---------- Auth Methods ----------
  void login() {
    isLoggedIn = true;
    generateData();
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    isOnboardingComplete = false;
    notifyListeners();
  }

  // ---------- User Methods ----------
  void updateProfile(
      String name, String email, int ageVal, int heightVal, int weightVal) {
    userName = name;
    userEmail = email;
    age = ageVal;
    height = heightVal;
    weight = weightVal;
    notifyListeners();
  }

  void completeOnboarding(String goal, String level, int steps) {
    fitnessGoal = goal;
    activityLevel = level;
    stepGoal = steps;
    isOnboardingComplete = true;
    generateData();
    notifyListeners();
  }

  void setUnitSystem(String unit) {
    unitSystem = unit;
    notifyListeners();
  }

  void toggleDailyReminders() {
    dailyReminders = !dailyReminders;
    notifyListeners();
  }

  void toggleWeeklyReports() {
    weeklyReports = !weeklyReports;
    notifyListeners();
  }

  void toggleAchievementAlerts() {
    achievementAlerts = !achievementAlerts;
    notifyListeners();
  }

  void toggleWorkoutTips() {
    workoutTips = !workoutTips;
    notifyListeners();
  }

  // ---------- Workout Methods ----------
  void startWorkout() {
    if (!isWorkoutActive) {
      isWorkoutActive = true;
      isPaused = false;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsedTime = _stopwatch.elapsed;
        _updateMetrics();
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void pauseWorkout() {
    if (isWorkoutActive && !isPaused) {
      isPaused = true;
      _stopwatch.stop();
      notifyListeners();
    } else if (isPaused) {
      isPaused = false;
      _stopwatch.start();
      notifyListeners();
    }
  }

  void stopWorkout() {
    if (isWorkoutActive) {
      _timer?.cancel();
      _stopwatch.stop();
      workoutHistory.add({
        'date': DateTime.now(),
        'type': activityType,
        'duration': elapsedTime,
        'distance': distance,
        'calories': calories,
        'pace': pace,
      });
      isWorkoutActive = false;
      isPaused = false;
      todayCalories += calories;
      activeMinutes += elapsedTime.inMinutes;
      notifyListeners();
    }
  }

  void resetWorkout() {
    _timer?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    elapsedTime = Duration.zero;
    distance = 0.0;
    pace = 0.0;
    calories = 0;
    isWorkoutActive = false;
    isPaused = false;
    notifyListeners();
  }

  void setActivityType(String type) {
    if (!isWorkoutActive) {
      activityType = type;
      notifyListeners();
    }
  }

  void _updateMetrics() {
    final double seconds = elapsedTime.inSeconds.toDouble();
    distance = (seconds * 0.012) * (activityType == 'Run' ? 1.5 : 1.0);
    calories = (seconds * 0.04).round();
    if (distance > 0) {
      pace = (seconds / 60) / distance;
    } else {
      pace = 0;
    }
  }

  String get formattedTime {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final int hours = elapsedTime.inHours;
    final int minutes = elapsedTime.inMinutes.remainder(60);
    final int seconds = elapsedTime.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ---------- SCREEN 1: SPLASH SCREEN ----------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.deepOrange],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'FitTrack',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Track. Improve. Achieve.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- SCREEN 2: LOGIN SCREEN ----------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter email and password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    final appState = Provider.of<AppState>(context, listen: false);
    appState.login();

    if (!appState.isOnboardingComplete) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.deepOrange],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to continue your fitness journey',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.orange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.orange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, '/onboarding');
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- SCREEN 3: ONBOARDING (4 Steps) ----------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  String selectedGoal = 'Lose Weight';
  String selectedLevel = 'Active';
  int stepGoal = 10000;
  final List<String> goals = [
    'Lose Weight',
    'Build Muscle',
    'Stay Active',
    'Train for Event'
  ];
  final List<String> levels = [
    'Sedentary',
    'Lightly Active',
    'Active',
    'Very Active'
  ];
  final List<int> stepOptions = [5000, 8000, 10000, 12000, 15000];

  final TextEditingController _ageController =
      TextEditingController(text: '28');
  final TextEditingController _heightController =
      TextEditingController(text: '175');
  final TextEditingController _weightController =
      TextEditingController(text: '72');

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: Container(),
      ),
      body: Column(
        children: [
          // Progress Dots
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: _currentStep == index ? 30 : 8,
                  decoration: BoxDecoration(
                    color: _currentStep == index
                        ? Colors.orange
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Steps counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentStep == 3) {
                      _finishOnboarding();
                    } else {
                      _pageController.jumpToPage(3);
                    }
                  },
                  child: Text(_currentStep == 3 ? 'Finish' : 'Skip'),
                ),
              ],
            ),
          ),
          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildGoalStep(),
                _buildPersonalStep(),
                _buildActivityStep(),
                _buildGoalStepFinal(),
              ],
            ),
          ),
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentStep == 0
                      ? null
                      : () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 3) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_currentStep == 3 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.completeOnboarding(
      selectedGoal,
      selectedLevel,
      stepGoal,
    );
    Navigator.pushReplacementNamed(context, '/main');
  }

  // Step 1: Goal
  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your main goal?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: selectedGoal == goal ? Colors.orange.shade100 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selectedGoal == goal
                          ? Colors.orange
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(goal),
                    trailing: selectedGoal == goal
                        ? const Icon(Icons.check_circle, color: Colors.orange)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedGoal = goal;
                      });
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Step 2: Personal Info
  Widget _buildPersonalStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tell us about you",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('This helps us personalize your targets.'),
          const SizedBox(height: 30),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Age',
              prefixIcon: const Icon(Icons.cake, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: const Icon(Icons.height, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon:
                  const Icon(Icons.monitor_weight, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // Step 3: Activity Level
  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How active are you?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...levels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: selectedLevel == level ? Colors.orange.shade100 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selectedLevel == level
                          ? Colors.orange
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(level),
                    trailing: selectedLevel == level
                        ? const Icon(Icons.check_circle, color: Colors.orange)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLevel = level;
                      });
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Step 4: Step Goal
  Widget _buildGoalStepFinal() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set your daily step goal",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...stepOptions.map((steps) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  color: stepGoal == steps ? Colors.orange.shade100 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: stepGoal == steps
                          ? Colors.orange
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text('$steps steps'),
                    trailing: stepGoal == steps
                        ? const Icon(Icons.check_circle, color: Colors.orange)
                        : null,
                    onTap: () {
                      setState(() {
                        stepGoal = steps;
                      });
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ---------- SCREEN 4: MAIN SCREEN (4 Tabs) ----------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WorkoutScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 5: DASHBOARD (FIXED) ----------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.weeklySteps.isEmpty || appState.monthlySteps.isEmpty) {
        appState.generateData();
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (_isLoading || appState.weeklySteps.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 20),
                  Text(
                    'Loading your fitness data...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final String greeting = _getGreeting();

        return Scaffold(
          appBar: AppBar(
            title: const Text('FitTrack'),
            backgroundColor: Colors.orange,
            elevation: 0,
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  appState.refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data refreshed! 🔄'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Refresh Data',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              appState.refreshData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          appState.userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, ${appState.userName}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Goal: ${appState.fitnessGoal}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Motivational Quote
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getMotivationalQuote(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.directions_walk,
                          label: 'Steps',
                          value: '${appState.todaySteps}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department,
                          label: 'Calories',
                          value: '${appState.todayCalories}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.access_time,
                          label: 'Active Min',
                          value: '${appState.activeMinutes}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.flag,
                          label: 'Goal',
                          value: '${appState.stepGoal}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Ring
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Daily Progress',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 120,
                              width: 120,
                              child: CircularProgressIndicator(
                                value: (appState.todaySteps / appState.stepGoal)
                                    .clamp(0.0, 1.0),
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.orange,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${((appState.todaySteps / appState.stepGoal) * 100).clamp(0.0, 100.0).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'of daily goal',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Workouts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Workouts',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  if (appState.workoutHistory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child:
                              Text('No workouts recorded yet. Start tracking!'),
                        ),
                      ),
                    )
                  else
                    ...appState.workoutHistory.reversed.take(3).map((workout) {
                      final duration = workout['duration'] as Duration;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            workout['type'] == 'Run'
                                ? Icons.directions_run
                                : workout['type'] == 'Cycle'
                                    ? Icons.directions_bike
                                    : Icons.directions_walk,
                            color: Colors.orange,
                          ),
                          title: Text(workout['type']),
                          subtitle: Text(
                            '${duration.inMinutes} min • ${workout['distance'].toStringAsFixed(2)} km',
                          ),
                          trailing: Text('${workout['calories']} kcal'),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getMotivationalQuote() {
    final quotes = [
      '"Small steps lead to big results."',
      '"Consistency is key to success."',
      '"Every workout counts. Keep going!"',
      '"Your only competition is yourself."',
      '"Progress, not perfection."',
      '"Believe in yourself and you\'re halfway there."',
      '"The only bad workout is the one that didn\'t happen."',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SCREEN 6: WORKOUT (Live Tracking) ----------
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Activity Type Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTypeChip('Walk', appState),
                    const SizedBox(width: 10),
                    _buildTypeChip('Run', appState),
                    const SizedBox(width: 10),
                    _buildTypeChip('Cycle', appState),
                  ],
                ),
                const SizedBox(height: 30),

                // Metrics Display
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        appState.formattedTime,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(
                            'Distance',
                            '${appState.distance.toStringAsFixed(2)} km',
                            Colors.blue,
                          ),
                          _buildMetric(
                            'Pace',
                            appState.pace > 0
                                ? '${appState.pace.toStringAsFixed(1)} /km'
                                : '--',
                            Colors.orange,
                          ),
                          _buildMetric(
                            'Calories',
                            '${appState.calories} kcal',
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!appState.isWorkoutActive)
                      ElevatedButton.icon(
                        onPressed: appState.startWorkout,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (appState.isWorkoutActive)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: appState.pauseWorkout,
                            icon: Icon(appState.isPaused
                                ? Icons.play_arrow
                                : Icons.pause),
                            label: Text(appState.isPaused ? 'Resume' : 'Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showStopDialog(context, appState);
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (appState.isWorkoutActive)
                  TextButton(
                    onPressed: () {
                      _showResetDialog(context, appState);
                    },
                    child: const Text('Reset'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String label, AppState state) {
    return FilterChip(
      label: Text(label),
      selected: state.activityType == label,
      onSelected: !state.isWorkoutActive
          ? (selected) => state.setActivityType(label)
          : null,
      selectedColor: Colors.orange,
      backgroundColor: Colors.grey.shade200,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _showStopDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Do you want to save this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.stopWorkout();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workout Saved! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Workout?'),
        content: const Text('This will discard the current workout data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.resetWorkout();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 7: STATS (FIXED) ----------
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data refreshed! 🔄'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Refresh Data',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.weeklySteps.isEmpty || appState.monthlySteps.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }

            return TabBarView(
              children: [
                // Weekly Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Steps',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 20000,
                            minY: 0,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const weekDays = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    return Text(weekDays[value.toInt()]);
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('0');
                                    if (value == 5000) return const Text('5k');
                                    if (value == 10000)
                                      return const Text('10k');
                                    if (value == 15000)
                                      return const Text('15k');
                                    if (value == 20000)
                                      return const Text('20k');
                                    return Container();
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              horizontalInterval: 5000,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 0.5,
                                );
                              },
                            ),
                            barGroups: List.generate(
                                appState.weeklySteps.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: appState.weeklySteps[index],
                                    color: Colors.orange,
                                    width: 24,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ],
                                showingTooltipIndicators: [],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Steps: ${appState.weeklySteps.reduce((a, b) => a + b).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '🔥 ~${(appState.weeklySteps.reduce((a, b) => a + b) * 0.04).toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Monthly Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Steps Trend',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 20000,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text((value.toInt() + 1).toString());
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('0');
                                    if (value == 5000) return const Text('5k');
                                    if (value == 10000)
                                      return const Text('10k');
                                    if (value == 15000)
                                      return const Text('15k');
                                    if (value == 20000)
                                      return const Text('20k');
                                    return Container();
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              horizontalInterval: 5000,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 0.5,
                                );
                              },
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                    appState.monthlySteps.length,
                                    (index) => FlSpot(index.toDouble(),
                                        appState.monthlySteps[index])),
                                isCurved: true,
                                color: Colors.orange,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.orange.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Steps: ${appState.monthlySteps.reduce((a, b) => a + b).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '🔥 ~${(appState.monthlySteps.reduce((a, b) => a + b) * 0.04).toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------- SCREEN 8: PROFILE ----------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.orange,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Avatar
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          appState.userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appState.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appState.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Menu Items
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Personal Info',
                  onTap: () {
                    Navigator.pushNamed(context, '/editProfile');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.monitor_weight,
                  title: 'Units',
                  subtitle: appState.unitSystem,
                  onTap: () {
                    _showUnitDialog(context, appState);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    _showNotificationsDialog(context, appState);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy',
                  onTap: () {
                    _showPrivacyDialog(context);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),

                const SizedBox(height: 20),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog(context, appState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null) Text(subtitle),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showUnitDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Unit System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Kilograms (kg)'),
              trailing: appState.unitSystem == 'kg'
                  ? const Icon(Icons.check_circle, color: Colors.orange)
                  : null,
              onTap: () {
                appState.setUnitSystem('kg');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pounds (lb)'),
              trailing: appState.unitSystem == 'lb'
                  ? const Icon(Icons.check_circle, color: Colors.orange)
                  : null,
              onTap: () {
                appState.setUnitSystem('lb');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Daily Reminders'),
              value: appState.dailyReminders,
              onChanged: (_) => appState.toggleDailyReminders(),
              activeThumbColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Weekly Reports'),
              value: appState.weeklyReports,
              onChanged: (_) => appState.toggleWeeklyReports(),
              activeThumbColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Achievement Alerts'),
              value: appState.achievementAlerts,
              onChanged: (_) => appState.toggleAchievementAlerts(),
              activeThumbColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Workout Tips'),
              value: appState.workoutTips,
              onChanged: (_) => appState.toggleWorkoutTips(),
              activeThumbColor: Colors.orange,
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Location Access'),
              trailing: const Icon(Icons.toggle_on, color: Colors.green),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.data_usage, color: Colors.orange),
              title: const Text('Data Sharing'),
              trailing: const Icon(Icons.toggle_off, color: Colors.red),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Clear History'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.orange),
              title: const Text('FAQ'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('FAQ section (coming soon)'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact support at support@fittrack.com'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
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

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 9: EDIT PROFILE ----------
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(text: appState.userName);
    _emailController = TextEditingController(text: appState.userEmail);
    _ageController = TextEditingController(text: appState.age.toString());
    _heightController = TextEditingController(text: appState.height.toString());
    _weightController = TextEditingController(text: appState.weight.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateProfile(
      _nameController.text,
      _emailController.text,
      int.parse(_ageController.text),
      int.parse(_heightController.text),
      int.parse(_weightController.text),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: const Icon(Icons.cake, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: const Icon(Icons.height, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon:
                    const Icon(Icons.monitor_weight, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
