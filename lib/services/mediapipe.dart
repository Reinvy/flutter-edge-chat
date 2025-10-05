import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MediaPipeGenAIService {
  static MediaPipeGenAIService? _instance;
  GenerativeModel? _model;
  bool _isInitialized = false;

  MediaPipeGenAIService._internal();

  static MediaPipeGenAIService get instance {
    _instance ??= MediaPipeGenAIService._internal();
    return _instance!;
  }

  Future<bool> initialize({bool useGpu = false}) async {
    try {
      if (_isInitialized) {
        return true;
      }

      // Use Google's Gemini model as a working alternative
      // The API key should be stored securely in production
      final apiKey =
          'AIzaSyBCJQhy2RlHSTEIiMTUYn0jJaciTlTJSU0'; // Replace with your actual API key
      _model = GenerativeModel(
        model: 'models/gemini-flash-lite-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 512,
        ),
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Google Generative AI: $e');
      return false;
    }
  }

  Future<String> generateResponse(String input) async {
    if (!_isInitialized || _model == null) {
      throw StateError(
        'Google Generative AI service not initialized. Call initialize() first.',
      );
    }

    try {
      final content = [Content.text(input)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating response: $e');
      throw Exception('Failed to generate response: $e');
    }
  }

  Future<String> generateResponseStream(
    String input,
    Function(String) onChunk,
  ) async {
    if (!_isInitialized || _model == null) {
      throw StateError(
        'Google Generative AI service not initialized. Call initialize() first.',
      );
    }

    try {
      final content = [Content.text(input)];
      final response = await _model!.generateContentStream(content);
      final StringBuffer responseBuffer = StringBuffer();

      await for (final chunk in response) {
        final text = chunk.text ?? '';
        responseBuffer.write(text);
        onChunk(text);
      }

      return responseBuffer.toString();
    } catch (e) {
      debugPrint('Error generating response stream: $e');
      throw Exception('Failed to generate response stream: $e');
    }
  }

  Future<String> _getModelPath() async {
    try {
      // For Google Generative AI, we don't need local model files
      // This method is kept for compatibility but returns empty string
      debugPrint('Using Google Generative AI - no local model needed');
      return '';
    } catch (e) {
      debugPrint('Error getting model path: $e');
      return '';
    }
  }

  void dispose() {
    _model = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}

// Helper function for backward compatibility
Future<String> getModelPath() async {
  return await MediaPipeGenAIService.instance._getModelPath();
}

// Example usage function
Future<void> exampleUsage() async {
  final service = MediaPipeGenAIService.instance;

  // Initialize the service
  final initialized = await service.initialize(useGpu: false);
  if (!initialized) {
    debugPrint('Failed to initialize MediaPipe GenAI service');
    return;
  }

  try {
    // Generate a response
    final response = await service.generateResponse('Hello, world!');
    debugPrint('Response: $response');

    // Generate response with streaming
    await service.generateResponseStream('What is artificial intelligence?', (
      chunk,
    ) {
      debugPrint('Chunk: $chunk');
    });
  } catch (e) {
    debugPrint('Error in example usage: $e');
  }
}
