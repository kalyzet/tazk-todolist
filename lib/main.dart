import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'l10n/app_localizations.dart';
import 'models/academic_context.dart';
import 'models/task.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'ui/screens/initial_setup_screen.dart';
import 'ui/screens/task_list_screen.dart';
import 'ui/screens/task_creation_screen.dart';
import 'ui/screens/task_editing_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const AcademicTaskManagerApp());
}

class AcademicTaskManagerApp extends StatelessWidget {
  const AcademicTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'Tazk',
        
        // Localization setup
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', ''), // Indonesian
        ],
        locale: const Locale('id', ''),
        
        // Theme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
          ),
        ),
        
        // Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const AppInitializer(),
          '/setup': (context) => const InitialSetupScreen(),
          '/task-list': (context) {
            final academicContext = ModalRoute.of(context)?.settings.arguments as AcademicContext?;
            return TaskListScreen(initialContext: academicContext);
          },
          '/task-create': (context) => const TaskCreationScreen(),
          '/task-edit': (context) {
            final task = ModalRoute.of(context)?.settings.arguments as Task;
            return TaskEditingScreen(task: task);
          },
          '/settings': (context) => const SettingsScreen(),
        },
        
        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const TaskListScreen(),
          );
        },
      ),
    );
  }
}

/// App initializer that determines the initial screen based on app state
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  bool _hasExistingData = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app and determine if we have existing data
  Future<void> _initializeApp() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.initialize();

      // Initialize notification service
      await NotificationService().initialize();
      
      // Check if we have existing context or tasks
      _hasExistingData = taskProvider.hasContext;
    } catch (e) {
      // Handle initialization error
      debugPrint('App initialization error: $e');
      _hasExistingData = false;
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat aplikasi...'),
            ],
          ),
        ),
      );
    }

    // Navigate to appropriate screen based on app state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasExistingData) {
        // User has existing data, go to task list
        Navigator.of(context).pushReplacementNamed('/task-list');
      } else {
        // New user, go to setup
        Navigator.of(context).pushReplacementNamed('/setup');
      }
    });

    // Show loading while navigation happens
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
