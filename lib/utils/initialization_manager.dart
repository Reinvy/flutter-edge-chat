import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Initialization Manager for managing app initialization states
/// 
/// This class provides centralized management of initialization states,
/// progress tracking, and error handling for all services.
class InitializationManager {
  static InitializationManager? _instance;
  
  // State variables
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _initializationFailed = false;
  String _errorMessage = '';
  int _progress = 0;
  String _currentStep = '';
  DateTime? _startTime;
  int _retryCount = 0;
  final int _maxRetries;
  final Duration _timeout;
  
  // Stream for initialization state changes
  final StreamController<InitializationState> _stateController = 
      StreamController<InitializationState>.broadcast();
  
  // Stream for progress updates
  final StreamController<InitializationProgress> _progressController = 
      StreamController<InitializationProgress>.broadcast();
  
  InitializationManager._internal({
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 45),
  }) : _maxRetries = maxRetries, _timeout = timeout;
  
  static InitializationManager get instance {
    _instance ??= InitializationManager._internal();
    return _instance!;
  }
  
  /// Get initialization state stream
  Stream<InitializationState> get stateStream => _stateController.stream;
  
  /// Get progress stream
  Stream<InitializationProgress> get progressStream => _progressController.stream;
  
  /// Get current state
  InitializationState get currentState => InitializationState(
    isInitialized: _isInitialized,
    isInitializing: _isInitializing,
    initializationFailed: _initializationFailed,
    errorMessage: _errorMessage,
    progress: _progress,
    currentStep: _currentStep,
    retryCount: _retryCount,
    elapsedTime: _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero,
  );

  /// Get retry count
  int get retryCount => _retryCount;
  
  /// Initialize all services with comprehensive error handling
  Future<bool> initializeAllServices({
    required Future<bool> Function() initializeFunction,
    String serviceName = 'Services',
  }) async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;
    
    _isInitializing = true;
    _initializationFailed = false;
    _errorMessage = '';
    _startTime = DateTime.now();
    _retryCount = 0;
    
    _notifyStateChange();
    _notifyProgressUpdate(0, 'Starting initialization...');
    
    while (_retryCount <= _maxRetries) {
      try {
        _retryCount++;
        _notifyProgressUpdate(10, 'Initializing $serviceName (attempt $_retryCount/$_maxRetries)...');
        
        // Initialize with timeout
        final initialized = await _initializeWithTimeout(
          initializeFunction,
          timeout: _timeout,
        );
        
        if (initialized) {
          _isInitialized = true;
          _isInitializing = false;
          _initializationFailed = false;
          _errorMessage = '';
          _progress = 100;
          _currentStep = 'Initialization completed';
          
          _notifyStateChange();
          _notifyProgressUpdate(100, 'Initialization completed');
          
          debugPrint('$serviceName initialized successfully');
          return true;
        } else {
          throw Exception('Initialization returned false');
        }
        
      } catch (e) {
        debugPrint('Initialization attempt $_retryCount failed: $e');
        
        if (_retryCount >= _maxRetries) {
          _isInitialized = false;
          _isInitializing = false;
          _initializationFailed = true;
          _errorMessage = e.toString();
          _progress = 0;
          _currentStep = 'Initialization failed';
          
          _notifyStateChange();
          _notifyProgressUpdate(0, 'Initialization failed');
          
          debugPrint('Failed to initialize $serviceName after $_maxRetries attempts: $e');
          return false;
        }
        
        // Wait before retrying with exponential backoff
        final waitTime = Duration(milliseconds: 1000 * _retryCount);
        _notifyProgressUpdate(5, 'Retrying in ${waitTime.inSeconds}s...');
        
        await Future.delayed(waitTime);
      }
    }
    
    return false;
  }
  
  /// Initialize with timeout
  Future<T> _initializeWithTimeout<T>(
    Future<T> Function() initFunction, {
    required Duration timeout,
  }) async {
    try {
      return await initFunction().timeout(timeout);
    } catch (e) {
      throw Exception('Initialization timeout: ${e.toString()}');
    }
  }
  
  /// Update progress
  void updateProgress(int progress, String step) {
    _progress = progress.clamp(0, 100);
    _currentStep = step;
    
    _notifyProgressUpdate(_progress, _currentStep);
  }
  
  /// Manual retry initialization
  Future<bool> retryInitialization({
    required Future<bool> Function() initializeFunction,
    String serviceName = 'Services',
  }) async {
    _retryCount = 0;
    _initializationFailed = false;
    _errorMessage = '';
    
    return await initializeAllServices(
      initializeFunction: initializeFunction,
      serviceName: serviceName,
    );
  }
  
  /// Check if initialization is in progress
  bool get isInitializing => _isInitializing;
  
  /// Check if initialization is complete
  bool get isInitialized => _isInitialized;
  
  /// Check if initialization failed
  bool get initializationFailed => _initializationFailed;
  
  /// Get error message
  String get errorMessage => _errorMessage;
  
  /// Get progress percentage
  int get progress => _progress;
  
  /// Get current step
  String get currentStep => _currentStep;
  
  /// Get elapsed time
  Duration get elapsedTime => _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
  
  /// Get formatted elapsed time
  String get formattedElapsedTime {
    final duration = elapsedTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Notify state change
  void _notifyStateChange() {
    try {
      _stateController.add(currentState);
    } catch (e) {
      debugPrint('Error notifying state change: $e');
    }
  }
  
  /// Notify progress update
  void _notifyProgressUpdate(int progress, String step) {
    try {
      _progressController.add(InitializationProgress(
        progress: progress,
        step: step,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error notifying progress update: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    try {
      _stateController.close();
      _progressController.close();
      debugPrint('InitializationManager disposed');
    } catch (e) {
      debugPrint('Error disposing InitializationManager: $e');
    }
  }
}

/// Initialization state data class
class InitializationState {
  final bool isInitialized;
  final bool isInitializing;
  final bool initializationFailed;
  final String errorMessage;
  final int progress;
  final String currentStep;
  final int retryCount;
  final Duration elapsedTime;
  
  InitializationState({
    required this.isInitialized,
    required this.isInitializing,
    required this.initializationFailed,
    required this.errorMessage,
    required this.progress,
    required this.currentStep,
    required this.retryCount,
    required this.elapsedTime,
  });
}

/// Initialization progress data class
class InitializationProgress {
  final int progress;
  final String step;
  final DateTime timestamp;
  
  InitializationProgress({
    required this.progress,
    required this.step,
    required this.timestamp,
  });
}

/// Extension for common initialization checks
extension InitializationExtensions on InitializationManager {
  /// Check if service is ready for use
  bool get isReady => isInitialized && !isInitializing && !initializationFailed;
  
  /// Get status message
  String get statusMessage {
    if (isInitializing) {
      return 'Initializing... ($formattedElapsedTime)';
    } else if (initializationFailed) {
      return 'Failed: $errorMessage';
    } else if (isInitialized) {
      return 'Ready';
    } else {
      return 'Not initialized';
    }
  }
  
  /// Get status color
  MaterialColor get statusColor {
    if (isInitializing) {
      return Colors.blue;
    } else if (initializationFailed) {
      return Colors.red;
    } else if (isInitialized) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
}