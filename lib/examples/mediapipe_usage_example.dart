import 'package:flutter/material.dart';
import 'dart:io' as io;
import '../services/tflite_local.dart';
import '../services/mediapipe.dart';
import '../helpers/mediapipe_helper.dart';

/// Example usage of TFLite-based AI service in a Flutter application
/// This file demonstrates how to use the new TFLite implementation
/// that replaces the previous MediaPipe GenAI service

class TFLiteUsageExample {
  /// Initialize the TFLite service when the app starts
  /// 
  /// [useGpu] - Whether to use GPU delegate for inference (if available)
  /// Returns true if initialization was successful
  static Future<bool> initializeService({bool useGpu = false}) async {
    try {
      debugPrint('Initializing TFLite AI service...');
      
      // Using MediaPipeHelper for backward compatibility
      final initialized = await MediaPipeHelper.initialize(
        useGpu: useGpu,
        useCloudFallback: false, // Disable cloud fallback for local inference
      );
      
      if (initialized) {
        debugPrint('TFLite AI service initialized successfully');
      } else {
        debugPrint('Failed to initialize TFLite AI service');
      }
      
      return initialized;
    } catch (e) {
      debugPrint('Error initializing TFLite service: $e');
      return false;
    }
  }

  /// Example of generating a simple response using TFLite
  /// 
  /// [input] - The input text to process
  /// [useGpu] - Whether to use GPU acceleration
  /// Returns the generated response text
  static Future<String> generateSimpleResponse(
    String input, {
    bool useGpu = false,
  }) async {
    try {
      debugPrint('Generating simple response with TFLite...');
      
      // Initialize with GPU if requested
      if (useGpu) {
        final initialized = await initializeService(useGpu: true);
        if (!initialized) {
          debugPrint('GPU initialization failed, falling back to CPU');
          await initializeService(useGpu: false);
        }
      }
      
      // Generate response using MediaPipeHelper (backward compatible)
      final response = await MediaPipeHelper.generateResponse(input);
      
      debugPrint('Response generated successfully: ${response.substring(0, min(50, response.length))}...');
      return response;
      
    } catch (e) {
      debugPrint('Error in generateSimpleResponse: $e');
      return 'Error: Unable to generate response - $e';
    }
  }

  /// Example of generating a streaming response using TFLite
  /// 
  /// [input] - The input text to process
  /// [onChunk] - Callback for streaming response chunks
  /// [onError] - Optional error callback
  /// [onComplete] - Optional completion callback
  /// [useGpu] - Whether to use GPU acceleration
  /// Returns the complete response text
  static Future<String> generateStreamingResponse(
    String input,
    Function(String) onChunk, {
    Function(String)? onError,
    Function()? onComplete,
    bool useGpu = false,
  }) async {
    try {
      debugPrint('Generating streaming response with TFLite...');
      
      // Initialize with GPU if requested
      if (useGpu) {
        final initialized = await initializeService(useGpu: true);
        if (!initialized) {
          debugPrint('GPU initialization failed, falling back to CPU');
          await initializeService(useGpu: false);
        }
      }
      
      // Generate streaming response using MediaPipeHelper
      final response = await MediaPipeHelper.generateResponseStream(
        input,
        (chunk) {
          onChunk(chunk);
          debugPrint('Chunk received: ${chunk.substring(0, min(30, chunk.length))}...');
        },
        onError: (error) {
          debugPrint('Streaming error: $error');
          onError?.call(error);
        },
        onComplete: () {
          debugPrint('Streaming response completed');
          onComplete?.call();
        },
      );
      
      return response;
      
    } catch (e) {
      debugPrint('Error in generateStreamingResponse: $e');
      onError?.call('Error: Unable to generate streaming response - $e');
      rethrow;
    }
  }

  /// Example of chat functionality with TFLite
  /// 
  /// [message] - The user message
  /// [conversationHistory] - List of previous conversation messages
  /// [onChunk] - Optional callback for streaming chunks
  /// [useGpu] - Whether to use GPU acceleration
  /// Returns the AI response
  static Future<String> chatWithAI(
    String message,
    List<String> conversationHistory, {
    Function(String)? onChunk,
    bool useGpu = false,
  }) async {
    // Build context from conversation history
    final context = conversationHistory.isNotEmpty
        ? 'Previous conversation:\n${conversationHistory.join('\n\n')}\n\nUser: $message\nAssistant:'
        : 'User: $message\nAssistant:';

    try {
      debugPrint('Starting TFLite chat session...');
      
      if (onChunk != null) {
        // Use streaming for real-time response
        return await generateStreamingResponse(
          context,
          onChunk,
          onComplete: () => debugPrint('Chat response completed'),
          useGpu: useGpu,
        );
      } else {
        // Use simple response for one-time generation
        return await generateSimpleResponse(context, useGpu: useGpu);
      }
    } catch (e) {
      debugPrint('Error in chatWithAI: $e');
      return 'I apologize, but I encountered an error while processing your request. Please try again.';
    }
  }

  /// Example of getting system information with TFLite
  /// 
  /// Returns formatted system information
  static Future<String> getSystemInfo() async {
    try {
      debugPrint('Getting TFLite system information...');
      
      // Get service status
      final serviceStatus = MediaPipeHelper.getServiceStatus();
      final detailedStatus = MediaPipeHelper.getDetailedServiceStatus();
      
      // Get model information
      final modelInfo = await MediaPipeHelper.getModelInfo();
      
      // Get initialization status
      final isInitialized = MediaPipeHelper.isInitialized;
      final useGpu = TFLiteLocalService.instance.useGpu;
      
      return '''
TFLite AI Service Information
============================

Service Status: $serviceStatus
Detailed Status: $detailedStatus
Initialized: ${isInitialized ? 'Yes' : 'No'}
GPU Acceleration: ${useGpu ? 'Enabled' : 'Disabled'}

Model Information:
-----------------
$modelInfo

System Details:
---------------
Platform: ${io.Platform.operatingSystem}
Flutter Version: ${const String.fromEnvironment('flutter.version')}
TFLite Version: ^0.11.0

Note: This service uses TensorFlow Lite for local AI inference.
''';
    } catch (e) {
      debugPrint('Error in getSystemInfo: $e');
      return 'Unable to retrieve system information: $e';
    }
  }

  /// Example of direct TFLite service usage
  /// 
  /// Demonstrates using the TFLite service directly instead of through MediaPipeHelper
  static Future<void> directTFLiteExample() async {
    try {
      debugPrint('=== Direct TFLite Service Example ===');
      
      // Get singleton instance
      final tfliteService = TFLiteLocalService.instance;
      
      // Initialize with GPU
      final initialized = await tfliteService.initialize(useGpu: true);
      if (!initialized) {
        debugPrint('GPU initialization failed, trying CPU...');
        await tfliteService.initialize(useGpu: false);
      }
      
      // Check initialization
      debugPrint('Service initialized: ${tfliteService.isInitialized}');
      debugPrint('Using GPU: ${tfliteService.useGpu}');
      
      // Get model path
      final modelPath = await tfliteService.getModelPath();
      debugPrint('Model path: $modelPath');
      
      // Generate response
      final response = await tfliteService.generateResponse(
        'Hello, TFLite! Can you tell me about yourself?',
      );
      debugPrint('Response: $response');
      
      // Generate streaming response
      final chunks = <String>[];
      await tfliteService.generateResponseStream(
        'Explain what TensorFlow Lite is and how it works on mobile devices.',
        (chunk) {
          chunks.add(chunk);
          debugPrint('Stream chunk: ${chunk.substring(0, min(30, chunk.length))}...');
        },
      );
      
      debugPrint('Full streaming response: ${chunks.join()}');
      
      // Cleanup
      tfliteService.dispose();
      debugPrint('TFLite service disposed');
      
    } catch (e) {
      debugPrint('Error in directTFLiteExample: $e');
    }
  }

  /// Example of error handling and recovery
  static Future<void> errorHandlingExample() async {
    try {
      debugPrint('=== Error Handling Example ===');
      
      // Try to initialize with invalid parameters
      try {
        await initializeService(useGpu: true);
      } catch (e) {
        debugPrint('Expected error during initialization: $e');
      }
      
      // Try to generate response without initialization
      try {
        await generateSimpleResponse('Test');
      } catch (e) {
        debugPrint('Expected error without initialization: $e');
      }
      
      // Proper initialization
      final initialized = await initializeService(useGpu: false);
      if (!initialized) {
        debugPrint('Failed to initialize service, skipping error handling example');
        return;
      }
      
      // Generate response with error handling
      final response = await generateSimpleResponse(
        'Hello, world!',
      );
      
      debugPrint('Response with error handling: $response');
      
    } catch (e) {
      debugPrint('Error in errorHandlingExample: $e');
    }
  }

  /// Example of performance benchmarking
  static Future<void> performanceBenchmark() async {
    try {
      debugPrint('=== Performance Benchmark Example ===');
      
      // Test different configurations
      const testInputs = [
        'Hello',
        'What is artificial intelligence?',
        'Explain the concept of machine learning in simple terms.',
        'Write a short story about a robot learning to paint.',
      ];
      
      // Test with CPU
      debugPrint('--- CPU Performance ---');
      await initializeService(useGpu: false);
      
      for (final input in testInputs) {
        final stopwatch = Stopwatch()..start();
        final response = await generateSimpleResponse(input);
        stopwatch.stop();
        
        debugPrint('Input length: ${input.length}, Response length: ${response.length}, Time: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      // Test with GPU (if available)
      debugPrint('--- GPU Performance ---');
      final gpuInitialized = await initializeService(useGpu: true);
      if (gpuInitialized) {
        for (final input in testInputs) {
          final stopwatch = Stopwatch()..start();
          final response = await generateSimpleResponse(input);
          stopwatch.stop();
          
          debugPrint('Input length: ${input.length}, Response length: ${response.length}, Time: ${stopwatch.elapsedMilliseconds}ms');
        }
      } else {
        debugPrint('GPU not available, skipping GPU performance test');
      }
      
    } catch (e) {
      debugPrint('Error in performanceBenchmark: $e');
    }
  }

  /// Clean up resources when the app closes
  static void dispose() {
    try {
      debugPrint('Cleaning up TFLite AI service...');
      MediaPipeHelper.dispose();
      debugPrint('TFLite service cleanup completed');
    } catch (e) {
      debugPrint('Error during TFLite service cleanup: $e');
    }
  }

  /// Comprehensive example demonstrating all features
  static Future<void> comprehensiveExample() async {
    try {
      debugPrint('=== Comprehensive TFLite AI Service Example ===');
      
      // 1. Initialize service
      debugPrint('1. Initializing service...');
      final initialized = await initializeService(useGpu: true);
      if (!initialized) {
        debugPrint('Failed to initialize service');
        return;
      }
      
      // 2. Get system information
      debugPrint('2. Getting system information...');
      final systemInfo = await getSystemInfo();
      debugPrint(systemInfo);
      
      // 3. Simple response generation
      debugPrint('3. Testing simple response generation...');
      final simpleResponse = await generateSimpleResponse(
        'Hello! Can you introduce yourself?',
      );
      debugPrint('Simple response: $simpleResponse');
      
      // 4. Streaming response generation
      debugPrint('4. Testing streaming response generation...');
      final streamingChunks = <String>[];
      await generateStreamingResponse(
        'Explain the benefits of using TensorFlow Lite for mobile AI.',
        (chunk) => streamingChunks.add(chunk),
        onComplete: () => debugPrint('Streaming completed'),
      );
      debugPrint('Streaming response: ${streamingChunks.join()}');
      
      // 5. Chat functionality
      debugPrint('5. Testing chat functionality...');
      final conversationHistory = [
        'User: What is AI?',
        'Assistant: AI stands for Artificial Intelligence.',
      ];
      final chatResponse = await chatWithAI(
        'Can you give me some examples of AI in everyday life?',
        conversationHistory,
        onChunk: (chunk) => debugPrint('Chat chunk: $chunk'),
      );
      debugPrint('Chat response: $chatResponse');
      
      // 6. Direct TFLite service usage
      debugPrint('6. Testing direct TFLite service usage...');
      await directTFLiteExample();
      
      // 7. Error handling
      debugPrint('7. Testing error handling...');
      await errorHandlingExample();
      
      // 8. Performance benchmarking
      debugPrint('8. Running performance benchmarks...');
      await performanceBenchmark();
      
      // 9. Cleanup
      debugPrint('9. Cleaning up resources...');
      dispose();
      
      debugPrint('=== Comprehensive Example Completed ===');
      
    } catch (e) {
      debugPrint('Error in comprehensiveExample: $e');
    }
  }
}

// Helper function to get minimum of two values
int min(int a, int b) => a < b ? a : b;
