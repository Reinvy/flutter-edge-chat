import 'package:flutter/material.dart';
import '../services/mediapipe.dart';

class MediaPipeHelper {
  static final MediaPipeGenAIService _service = MediaPipeGenAIService.instance;

  /// Initialize MediaPipe GenAI service
  static Future<bool> initialize({bool useGpu = false}) async {
    try {
      debugPrint('Initializing MediaPipe GenAI service...');
      final initialized = await _service.initialize(useGpu: useGpu);
      if (initialized) {
        debugPrint('MediaPipe GenAI service initialized successfully');
      } else {
        debugPrint('Failed to initialize MediaPipe GenAI service');
      }
      return initialized;
    } catch (e) {
      debugPrint('Error initializing MediaPipe GenAI service: $e');
      return false;
    }
  }

  /// Generate a response from the model
  static Future<String> generateResponse(String input) async {
    try {
      debugPrint('Generating response for: $input');
      final response = await _service.generateResponse(input);
      debugPrint('Response generated successfully');
      return response;
    } catch (e) {
      debugPrint('Error generating response: $e');
      rethrow;
    }
  }

  /// Generate response with streaming support
  static Future<String> generateResponseStream(
    String input,
    Function(String) onChunk, {
    Function(String)? onError,
    Function()? onComplete,
  }) async {
    try {
      debugPrint('Generating response stream for: $input');
      final response = await _service.generateResponseStream(input, (chunk) {
        onChunk(chunk);
      });

      onComplete?.call();
      debugPrint('Response stream completed');
      return response;
    } catch (e) {
      debugPrint('Error in response stream: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _service.isInitialized;

  /// Dispose the service
  static void dispose() {
    _service.dispose();
    debugPrint('MediaPipe GenAI service disposed');
  }

  /// Get model information
  static Future<String> getModelInfo() async {
    return 'Model: gemma3-270m-it-q8.task\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
  }
}
