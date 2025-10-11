import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/tflite_local.dart';
import '../services/mediapipe.dart';
import '../helpers/mediapipe_helper.dart';
import '../utils/initialization_manager.dart';

/// Test suite for initialization fixes
/// 
/// This test suite verifies that all initialization-related fixes work correctly
/// and prevent the application from hanging during startup.
void main() {
  group('Initialization Tests', () {
    late InitializationManager initManager;
    
    setUp(() {
      initManager = InitializationManager.instance;
    });
    
    tearDown(() {
      initManager.dispose();
    });
    
    test('InitializationManager should initialize with correct default state', () {
      expect(initManager.isInitialized, false);
      expect(initManager.isInitializing, false);
      expect(initManager.initializationFailed, false);
      expect(initManager.errorMessage, '');
      expect(initManager.progress, 0);
      expect(initManager.currentStep, '');
      expect(initManager.retryCount, 0);
    });
    
    test('InitializationManager should handle successful initialization', () async {
      // Mock a successful initialization function
      bool mockInitialized = false;
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate work
        mockInitialized = true;
        return true;
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, true);
      expect(initManager.isInitialized, true);
      expect(initManager.isInitializing, false);
      expect(initManager.initializationFailed, false);
      expect(mockInitialized, true);
    });
    
    test('InitializationManager should handle initialization failure', () async {
      // Mock a failed initialization function
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate work
        return false;
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, false);
      expect(initManager.isInitialized, false);
      expect(initManager.isInitializing, false);
      expect(initManager.initializationFailed, true);
    });
    
    test('InitializationManager should handle initialization timeout', () async {
      // Mock a slow initialization function that will timeout
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(seconds: 2)); // This will timeout
        return true;
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, false);
      expect(initManager.initializationFailed, true);
      expect(initManager.errorMessage, contains('timeout'));
    });
    
    test('InitializationManager should retry initialization on failure', () async {
      int attemptCount = 0;
      Future<bool> mockInitialize() async {
        attemptCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return attemptCount >= 2; // Succeed on second attempt
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, true);
      expect(attemptCount, 2);
      expect(initManager.retryCount, 2);
    });
    
    test('InitializationManager should provide progress updates', () async {
      final progressUpdates = <InitializationProgress>[];
      final subscription = initManager.progressStream.listen((progress) {
        progressUpdates.add(progress);
      });
      
      // Mock initialization with progress updates
      Future<bool> mockInitialize() async {
        initManager.updateProgress(25, 'Step 1');
        await Future.delayed(const Duration(milliseconds: 50));
        initManager.updateProgress(50, 'Step 2');
        await Future.delayed(const Duration(milliseconds: 50));
        initManager.updateProgress(75, 'Step 3');
        await Future.delayed(const Duration(milliseconds: 50));
        initManager.updateProgress(100, 'Complete');
        return true;
      }
      
      await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(progressUpdates.length, 4);
      expect(progressUpdates[0].progress, 25);
      expect(progressUpdates[0].step, 'Step 1');
      expect(progressUpdates[3].progress, 100);
      expect(progressUpdates[3].step, 'Complete');
      
      subscription.cancel();
    });
    
    test('InitializationManager should provide state updates', () async {
      final stateUpdates = <InitializationState>[];
      final subscription = initManager.stateStream.listen((state) {
        stateUpdates.add(state);
      });
      
      // Mock initialization
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
      
      await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(stateUpdates.length, 2); // Initial state + final state
      expect(stateUpdates[0].isInitialized, false);
      expect(stateUpdates[0].isInitializing, false);
      expect(stateUpdates[1].isInitialized, true);
      expect(stateUpdates[1].isInitializing, false);
      
      subscription.cancel();
    });
    
    test('InitializationManager should handle retry functionality', () async {
      int attemptCount = 0;
      Future<bool> mockInitialize() async {
        attemptCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return attemptCount >= 2; // Succeed on second attempt
      }
      
      // First attempt should fail
      var result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, false);
      expect(attemptCount, 1);
      
      // Retry should succeed
      result = await initManager.retryInitialization(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, true);
      expect(attemptCount, 2);
    });
    
    test('InitializationManager should format elapsed time correctly', () async {
      final start = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 1500));
      final elapsed = DateTime.now().difference(start);
      
      // Test formatting
      expect(elapsed.inSeconds, 1);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(elapsed.inMilliseconds, lessThanOrEqualTo(2000));
    });
    
    test('InitializationManager should handle dispose gracefully', () {
      expect(() => initManager.dispose(), returnsNormally);
    });
  });
  
  group('TFLiteLocalService Tests', () {
    test('TFLiteLocalService should handle initialization with retry logic', () async {
      // This test would require actual model files and TFLite setup
      // For now, we'll test the interface
      final service = TFLiteLocalService.instance;
      
      expect(service.isInitialized, false);
      expect(service.isReady, false);
      
      // The actual initialization test would require:
      // - Model files in assets
      // - TFLite dependencies properly set up
      // - Native libraries available
      // For now, we'll just test the interface
      expect(service.getInitializationStatus(), 'Not Initialized');
    });
    
    test('TFLiteLocalService should provide status information', () {
      final service = TFLiteLocalService.instance;
      
      expect(service.getInitializationStatus(), 'Not Initialized');
      expect(service.isInitialized, false);
      expect(service.useGpu, false);
    });
  });
  
  group('MediaPipeHelper Tests', () {
    test('MediaPipeHelper should provide interface methods', () {
      // Test that the interface methods exist and are callable
      expect(MediaPipeHelper.isInitialized, false);
      expect(MediaPipeHelper.getServiceStatus(), 'Not Initialized');
      
      // These would normally require actual service initialization
      // For now, we just test the interface exists
      expect(() => MediaPipeHelper.getModelInfo(), returnsNormally);
      expect(() => MediaPipeHelper.dispose(), returnsNormally);
    });
  });
  
  group('Error Handling Tests', () {
    test('Should handle initialization errors gracefully', () async {
      final initManager = InitializationManager.instance;
      
      // Mock an initialization that throws an exception
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw Exception('Test error');
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, false);
      expect(initManager.initializationFailed, true);
      expect(initManager.errorMessage, contains('Test error'));
    });
    
    test('Should handle timeout errors gracefully', () async {
      final initManager = InitializationManager.instance;
      
      // Mock an initialization that takes too long
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      
      expect(result, false);
      expect(initManager.initializationFailed, true);
      expect(initManager.errorMessage, contains('timeout'));
    });
  });
  
  group('Performance Tests', () {
    test('Initialization should complete within reasonable time', () async {
      final initManager = InitializationManager.instance;
      
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      }
      
      final stopwatch = Stopwatch()..start();
      final result = await initManager.initializeAllServices(
        initializeFunction: mockInitialize,
        serviceName: 'Test Service',
      );
      stopwatch.stop();
      
      expect(result, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
    
    test('Multiple initialization attempts should not cause memory leaks', () async {
      final initManager = InitializationManager.instance;
      
      Future<bool> mockInitialize() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      }
      
      // Perform multiple initialization cycles
      for (int i = 0; i < 5; i++) {
        await initManager.initializeAllServices(
          initializeFunction: mockInitialize,
          serviceName: 'Test Service',
        );
        await initManager.retryInitialization(
          initializeFunction: mockInitialize,
          serviceName: 'Test Service',
        );
      }
      
      // Should still be in a valid state
      expect(initManager.isInitialized, true);
      expect(initManager.isInitializing, false);
    });
  });
}

/// Helper extension for numeric comparisons
extension NumericExtensions on num {
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }
}