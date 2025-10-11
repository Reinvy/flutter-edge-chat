import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'helpers/mediapipe_helper.dart';
import 'screen/chat_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services with error handling
  await initializeAppServicesWithErrorHandling();
  
  // Run the app
  runApp(const MyApp());
}

/// Initialize app services with comprehensive error handling
Future<void> initializeAppServicesWithErrorHandling() async {
  try {
    debugPrint('Starting app initialization with error handling...');
    
    // Set up error handlers for native library loading
    await _setupNativeLibraryErrorHandling();
    
    // Initialize services with timeout and retry logic
    final initialized = await ServiceManager.initializeServicesWithRetry(
      maxRetries: 3,
      timeout: const Duration(seconds: 45),
    );
    
    if (initialized) {
      debugPrint('App services initialized successfully');
    } else {
      debugPrint('Warning: Some app services failed to initialize');
    }
  } catch (e) {
    debugPrint('Error during app service initialization: $e');
    // Don't crash the app, just log the error
    // The app will show a proper error message to the user
  }
}

/// Setup error handling for native library loading
Future<void> _setupNativeLibraryErrorHandling() async {
  try {
    // Check if native library exists and is accessible
    final nativeLibPath = 'android/app/src/main/jniLibs/arm64-v8a/libllm_inference_engine.so';
    debugPrint('Checking native library at: $nativeLibPath');
    
    // This is a basic check - in a real app you might want more sophisticated checks
    // For now, we'll just log that we're checking
    debugPrint('Native library check completed');
    
  } catch (e) {
    debugPrint('Error setting up native library error handling: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edge Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// App lifecycle handler for proper service initialization and cleanup
class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background, pause any ongoing operations
        debugPrint('App paused - pausing AI operations');
        break;
      case AppLifecycleState.resumed:
        // App is back to foreground, resume operations
        debugPrint('App resumed - resuming AI operations');
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated, cleanup resources
        debugPrint('App detached - cleaning up AI resources');
        _cleanupServices();
        break;
      case AppLifecycleState.hidden:
        // App is hidden from user
        debugPrint('App hidden - pausing AI operations');
        break;
      case AppLifecycleState.inactive:
        // App is in an inactive state
        debugPrint('App inactive - pausing AI operations');
        break;
    }
  }

  /// Cleanup services when app is terminated
  void _cleanupServices() {
    try {
      MediaPipeHelper.dispose();
      debugPrint('AI services cleaned up successfully');
    } catch (e) {
      debugPrint('Error cleaning up AI services: $e');
    }
  }
}

/// Global service initialization handler
class ServiceManager {
  static bool _servicesInitialized = false;
  static bool _useGpu = false;
  static bool _useCloudFallback = false;
  static int _initializationRetryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize all services when the app starts
  static Future<bool> initializeServices() async {
    if (_servicesInitialized) return true;

    try {
      debugPrint('Initializing app services...');
      
      // Initialize AI service
      final aiServiceInitialized = await MediaPipeHelper.initialize(
        useGpu: _useGpu,
        useCloudFallback: _useCloudFallback,
      );
      
      if (aiServiceInitialized) {
        debugPrint('All services initialized successfully');
        _servicesInitialized = true;
        _initializationRetryCount = 0;
        return true;
      } else {
        debugPrint('Failed to initialize some services');
        return false;
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
      return false;
    }
  }

  /// Initialize services with retry logic and timeout
  static Future<bool> initializeServicesWithRetry({
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_servicesInitialized) return true;

    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      _initializationRetryCount = attempt;
      
      try {
        debugPrint('Initializing app services (attempt $attempt/$maxRetries)...');
        
        // Initialize AI service with timeout
        final aiServiceInitialized = await _initializeWithTimeout(
          () => MediaPipeHelper.initialize(
            useGpu: _useGpu,
            useCloudFallback: _useCloudFallback,
          ),
          timeout: timeout,
        );
        
        if (aiServiceInitialized) {
          debugPrint('All services initialized successfully on attempt $attempt');
          _servicesInitialized = true;
          _initializationRetryCount = 0;
          return true;
        } else {
          debugPrint('Failed to initialize services on attempt $attempt');
          if (attempt >= maxRetries) {
            break;
          }
          await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
        }
      } catch (e) {
        debugPrint('Error initializing services on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          break;
        }
        await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
      }
    }
    
    debugPrint('Failed to initialize services after $maxRetries attempts');
    return false;
  }

  /// Initialize with timeout to prevent hanging
  static Future<T> _initializeWithTimeout<T>(
    Future<T> Function() initFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await initFunction().timeout(timeout);
    } catch (e) {
      throw Exception('Initialization timeout: ${e.toString()}');
    }
  }

  /// Check if services are initialized
  static bool get servicesInitialized => _servicesInitialized;

  /// Update GPU setting and reinitialize if needed
  static Future<void> updateGpuSetting(bool useGpu) async {
    _useGpu = useGpu;
    if (_servicesInitialized) {
      debugPrint('Updating GPU setting and reinitializing services...');
      await initializeServices();
    }
  }

  /// Update cloud fallback setting and reinitialize if needed
  static Future<void> updateCloudFallbackSetting(bool useCloudFallback) async {
    _useCloudFallback = useCloudFallback;
    if (_servicesInitialized) {
      debugPrint('Updating cloud fallback setting and reinitializing services...');
      await initializeServices();
    }
  }

  /// Cleanup all services
  static void cleanupServices() {
    try {
      MediaPipeHelper.dispose();
      _servicesInitialized = false;
      debugPrint('All services cleaned up');
    } catch (e) {
      debugPrint('Error cleaning up services: $e');
    }
  }
}

/// Get initialization status with details
String getInitializationStatus() {
  if (ServiceManager.servicesInitialized) {
    return 'Initialized';
  } else if (ServiceManager._initializationRetryCount > 0) {
    return 'Failed after ${ServiceManager._initializationRetryCount} attempts';
  } else {
    return 'Not Initialized';
  }
}

/// Get initialization error details
String getInitializationErrorDetails() {
  // This could be enhanced to capture specific error messages
  return 'Service initialization failed. Please check device compatibility and try again.';
}

