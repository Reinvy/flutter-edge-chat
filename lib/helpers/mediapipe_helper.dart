import 'package:flutter/material.dart';
import '../services/mediapipe.dart';

/// MediaPipe Helper
///
/// This helper provides convenience methods for working with the updated
/// MediaPipe GenAI service implementation using TFLiteLocalService.
class MediaPipeHelper {
  /// Initialize AI service with TFLiteLocalService
  ///
  /// [useGpu] - Whether to use GPU delegate for inference (if available)
  /// [useCloudFallback] - Whether to enable cloud service fallback
  /// Returns true if initialization was successful
  static Future<bool> initialize({bool useGpu = false, bool useCloudFallback = false}) async {
    try {
      debugPrint('Initializing AI Service through MediaPipeHelper...');
      final initialized = await MediaPipeGenAIService.instance.initialize(
        useGpu: useGpu,
        useCloudFallback: useCloudFallback,
      );
      
      if (initialized) {
        debugPrint('AI Service initialized successfully');
      } else {
        debugPrint('Failed to initialize AI Service');
      }
      
      return initialized;
    } catch (e) {
      debugPrint('Error initializing AI Service: $e');
      return false;
    }
  }

  /// Generate a response from the model
  ///
  /// [input] - The input text to process
  /// [onError] - Optional error callback
  /// Returns the generated response text
  static Future<String> generateResponse(String input, {Function(String)? onError}) async {
    try {
      debugPrint('Generating response through MediaPipeHelper...');
      final response = await MediaPipeGenAIService.instance.generateResponse(input);
      debugPrint('Response generated successfully');
      return response;
    } catch (e) {
      debugPrint('Error generating response: $e');
      onError?.call('Failed to generate response: $e');
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Generate response with streaming support
  ///
  /// [input] - The input text to process
  /// [onChunk] - Callback for streaming response chunks
  /// [onError] - Optional error callback
  /// [onComplete] - Optional completion callback
  /// Returns the complete response text
  static Future<String> generateResponseStream(
    String input,
    Function(String) onChunk, {
    Function(String)? onError,
    Function()? onComplete,
  }) async {
    try {
      debugPrint('Generating streaming response through MediaPipeHelper...');
      final response = await MediaPipeGenAIService.instance.generateResponseStream(
        input,
        (chunk) {
          onChunk(chunk);
        },
      );
      
      debugPrint('Streaming response completed');
      onComplete?.call();
      return response;
    } catch (e) {
      debugPrint('Error generating streaming response: $e');
      onError?.call('Failed to generate streaming response: $e');
      throw Exception('Failed to generate streaming response: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => MediaPipeGenAIService.instance.isInitialized;

  /// Dispose the service
  static void dispose() {
    try {
      debugPrint('Disposing AI Service through MediaPipeHelper');
      MediaPipeGenAIService.instance.dispose();
    } catch (e) {
      debugPrint('Error disposing AI Service: $e');
    }
  }

  /// Get model information
  static Future<String> getModelInfo() async {
    try {
      return await MediaPipeGenAIService.instance.getModelInfo();
    } catch (e) {
      debugPrint('Error getting model info: $e');
      return 'AI Service: Error\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
    }
  }

  /// Get model path
  static Future<String> getModelPath() async {
    try {
      return await MediaPipeGenAIService.instance.getModelPath();
    } catch (e) {
      debugPrint('Error getting model path: $e');
      return '';
    }
  }

  /// Check if cloud fallback is enabled
  static bool get useCloudFallback => MediaPipeGenAIService.instance.useCloudFallback;

  /// Enable or disable cloud fallback
  static set useCloudFallback(bool enabled) {
    MediaPipeGenAIService.instance.useCloudFallback = enabled;
  }

  /// Get service status as a formatted string
  static String getServiceStatus() {
    if (!isInitialized) {
      return 'Not Initialized';
    }
    
    return 'Active (TFLiteLocalService)';
  }

  /// Get service status with cloud fallback info
  static String getDetailedServiceStatus() {
    final status = isInitialized ? 'Active' : 'Not Initialized';
    final serviceType = 'TFLiteLocalService';
    const cloudFallback = 'Disabled'; // Cloud fallback not implemented yet
    
    return 'Status: $status\nService: $serviceType\nCloud Fallback: $cloudFallback';
  }

  /// Convenience method for quick chat initialization
  static Future<bool> initializeForChat({bool useGpu = false}) async {
    return initialize(
      useGpu: useGpu,
      useCloudFallback: false, // Disable cloud fallback for chat to ensure local processing
    );
  }

  /// Convenience method for quick chat response generation
  static Future<String> generateChatResponse(String input, {Function(String)? onError}) async {
    return generateResponse(input, onError: onError);
  }

  /// Convenience method for quick chat streaming response
  static Future<String> generateChatResponseStream(
    String input,
    Function(String) onChunk, {
    Function(String)? onError,
    Function()? onComplete,
  }) async {
    return generateResponseStream(
      input,
      onChunk,
      onError: onError,
      onComplete: onComplete,
    );
  }
}
