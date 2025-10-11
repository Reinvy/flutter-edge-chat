// TFLite Local Service Implementation
// This service provides local AI inference using TFLite models
// to replace the previous MediaPipe GenAI functionality

import 'package:flutter/foundation.dart';
import 'tflite_local.dart';
import '../utils/model_converter.dart';

class MediaPipeLocalGenAIService {
  static MediaPipeLocalGenAIService? _instance;

  MediaPipeLocalGenAIService._internal();

  static MediaPipeLocalGenAIService get instance {
    _instance ??= MediaPipeLocalGenAIService._internal();
    return _instance!;
  }

  Future<bool> initialize({bool useGpu = false}) async {
    try {
      debugPrint('Initializing MediaPipe Local GenAI Service with TFLite...');
      final initialized = await TFLiteLocalService.instance.initialize(useGpu: useGpu);

      if (initialized) {
        debugPrint('MediaPipe Local GenAI Service initialized successfully');
      } else {
        debugPrint('Failed to initialize MediaPipe Local GenAI Service');
      }

      return initialized;
    } catch (e) {
      debugPrint('Error initializing MediaPipe Local GenAI Service: $e');
      return false;
    }
  }

  Future<String> generateResponse(String input) async {
    try {
      if (!TFLiteLocalService.instance.isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }

      debugPrint('Generating response for input: $input');
      final response = await TFLiteLocalService.instance.generateResponse(input);
      debugPrint('Response generated successfully');
      return response;
    } catch (e) {
      debugPrint('Error generating response: $e');
      throw Exception('Failed to generate response: $e');
    }
  }

  Future<String> generateResponseStream(String input, Function(String) onChunk) async {
    try {
      if (!TFLiteLocalService.instance.isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }

      debugPrint('Generating streaming response for input: $input');
      final response = await TFLiteLocalService.instance.generateResponseStream(input, onChunk);
      debugPrint('Streaming response completed');
      return response;
    } catch (e) {
      debugPrint('Error generating streaming response: $e');
      throw Exception('Failed to generate streaming response: $e');
    }
  }

  void dispose() {
    try {
      debugPrint('Disposing MediaPipe Local GenAI Service');
      TFLiteLocalService.instance.dispose();
    } catch (e) {
      debugPrint('Error disposing MediaPipe Local GenAI Service: $e');
    }
  }

  bool get isInitialized => TFLiteLocalService.instance.isInitialized;

  // Additional convenience methods for backward compatibility
  Future<String> getModelPath() async {
    try {
      return await TFLiteLocalService.instance.getModelPath();
    } catch (e) {
      debugPrint('Error getting model path: $e');
      return '';
    }
  }

  Future<String> getModelInfo() async {
    try {
      final modelPath = await getModelPath();
      if (modelPath.isEmpty) {
        return 'Model: Not Available\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
      }
      
      // Use ModelConverter to get model information
      return await ModelConverter.getModelInfo(modelPath);
    } catch (e) {
      debugPrint('Error getting model info: $e');
      return 'Model: Error\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
    }
  }
}

// Helper function for backward compatibility
Future<String> getModelPath() async {
  try {
    return await TFLiteLocalService.instance.getModelPath();
  } catch (e) {
    debugPrint('Error getting model path: $e');
    return '';
  }
}

// Example usage function
Future<void> exampleUsage() async {
  try {
    debugPrint('MediaPipe Local GenAI Service Example Usage');

    // Initialize the service
    final initialized = await MediaPipeLocalGenAIService.instance.initialize(useGpu: false);
    if (!initialized) {
      debugPrint('Failed to initialize service');
      return;
    }

    // Generate a response
    final response = await MediaPipeLocalGenAIService.instance.generateResponse(
      'Hello, how are you?',
    );
    debugPrint('Response: $response');

    // Generate streaming response
    final chunks = <String>[];
    await MediaPipeLocalGenAIService.instance.generateResponseStream(
      'Tell me about artificial intelligence',
      (chunk) {
        chunks.add(chunk);
        debugPrint('Chunk: $chunk');
      },
    );

    debugPrint('Full streaming response: ${chunks.join()}');

    // Cleanup
    MediaPipeLocalGenAIService.instance.dispose();
  } catch (e) {
    debugPrint('Error in example usage: $e');
  }
}
