import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'services/database_service.dart';
import 'pages/auth/landing_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/auth/gender_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/change_password_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/tracking/workout_log_page.dart';
import 'pages/tracking/hydration_page.dart';
import 'pages/tracking/symptoms_page.dart';
import 'pages/tracking/period_tracker_page.dart';
import 'pages/nutrition/nutrition_page.dart';
import 'pages/nutrition/meal_plan_page.dart';
import 'pages/wellness/mood_tracker_page.dart';
import 'pages/wellness/meditation_page.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await DatabaseService().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return MaterialApp(
      title: 'NovaHealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: isLoggedIn ? AppRoutes.home : AppRoutes.landing,
      routes: {
        AppRoutes.landing: (context) => const LandingPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.signup: (context) => const SignupPage(),
        AppRoutes.gender: (context) => const GenderPage(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.editProfile: (context) => const EditProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.workoutLog: (context) => const WorkoutLogPage(),
        AppRoutes.hydration: (context) => const HydrationPage(),
        AppRoutes.symptoms: (context) => const SymptomsPage(),
        AppRoutes.periodTracker: (context) => const PeriodTrackerPage(),
        AppRoutes.nutrition: (context) => const NutritionPage(),
        AppRoutes.mealPlan: (context) => const MealPlanPage(),
        AppRoutes.moodTracker: (context) => const MoodTrackerPage(),
        AppRoutes.meditation: (context) => const MeditationPage(),
      },
    );
  }
}
