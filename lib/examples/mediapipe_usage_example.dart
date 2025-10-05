import 'package:flutter/material.dart';
import '../helpers/mediapipe_helper.dart';

/// Example usage of MediaPipe GenAI service in a Flutter application
class MediaPipeUsageExample {
  /// Initialize the service when the app starts
  static Future<void> initializeService() async {
    final initialized = await MediaPipeHelper.initialize(useGpu: false);
    if (!initialized) {
      debugPrint('Failed to initialize MediaPipe GenAI service');
      return;
    }
    debugPrint('MediaPipe GenAI service is ready');
  }

  /// Example of generating a simple response
  static Future<String> generateSimpleResponse(String input) async {
    try {
      return await MediaPipeHelper.generateResponse(input);
    } catch (e) {
      debugPrint('Error in generateSimpleResponse: $e');
      return 'Error: Unable to generate response';
    }
  }

  /// Example of generating a streaming response
  static Future<String> generateStreamingResponse(
    String input,
    Function(String) onChunk, {
    Function(String)? onError,
    Function()? onComplete,
  }) async {
    try {
      return await MediaPipeHelper.generateResponseStream(
        input,
        onChunk,
        onError: onError,
        onComplete: onComplete,
      );
    } catch (e) {
      debugPrint('Error in generateStreamingResponse: $e');
      rethrow;
    }
  }

  /// Example of chat functionality
  static Future<String> chatWithAI(
    String message,
    List<String> conversationHistory, {
    Function(String)? onChunk,
  }) async {
    // Build context from conversation history
    final context = conversationHistory.isNotEmpty
        ? 'Previous conversation:\n${conversationHistory.join('\n\n')}\n\nUser: $message\nAssistant:'
        : 'User: $message\nAssistant:';

    try {
      if (onChunk != null) {
        // Use streaming for real-time response
        return await generateStreamingResponse(
          context,
          onChunk,
          onComplete: () => debugPrint('Chat response completed'),
        );
      } else {
        // Use simple response for one-time generation
        return await generateSimpleResponse(context);
      }
    } catch (e) {
      debugPrint('Error in chatWithAI: $e');
      return 'I apologize, but I encountered an error while processing your request. Please try again.';
    }
  }

  /// Example of getting model information
  static Future<String> getSystemInfo() async {
    try {
      final modelInfo = await MediaPipeHelper.getModelInfo();
      final status = MediaPipeHelper.isInitialized
          ? 'Ready'
          : 'Not Initialized';
      return 'MediaPipe GenAI Status: $status\n\n$modelInfo';
    } catch (e) {
      debugPrint('Error in getSystemInfo: $e');
      return 'Unable to retrieve system information';
    }
  }

  /// Clean up resources when the app closes
  static void dispose() {
    MediaPipeHelper.dispose();
    debugPrint('MediaPipe GenAI service cleaned up');
  }
}
