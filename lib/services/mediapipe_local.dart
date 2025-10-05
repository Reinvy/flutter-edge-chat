import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'package:path_provider/path_provider.dart';

class MediaPipeLocalGenAIService {
  static MediaPipeLocalGenAIService? _instance;
  LlmInferenceEngine? _engine;
  bool _isInitialized = false;

  MediaPipeLocalGenAIService._internal();

  static MediaPipeLocalGenAIService get instance {
    _instance ??= MediaPipeLocalGenAIService._internal();
    return _instance!;
  }

  Future<bool> initialize({bool useGpu = false}) async {
    try {
      if (_isInitialized) {
        return true;
      }

      final modelPath = await _getModelPath();

      // Select the CPU or GPU runtime, based on your model
      final options = useGpu
          ? LlmInferenceOptions.gpu(
              modelPath: modelPath,
              sequenceBatchSize: 1,
              maxTokens: 512,
              temperature: 0.7,
              topK: 40,
            )
          : LlmInferenceOptions.cpu(
              modelPath: modelPath,
              cacheDir: (await getApplicationDocumentsDirectory()).path,
              maxTokens: 512,
              temperature: 0.7,
              topK: 40,
            );

      // Create an inference engine
      _engine = LlmInferenceEngine(options);
      _isInitialized = true;

      return true;
    } catch (e) {
      debugPrint('Failed to initialize MediaPipe GenAI: $e');
      return false;
    }
  }

  Future<String> generateResponse(String input) async {
    if (!_isInitialized || _engine == null) {
      throw StateError(
        'MediaPipe GenAI service not initialized. Call initialize() first.',
      );
    }

    try {
      final Stream<String> responseStream = _engine!.generateResponse(input);
      final StringBuffer responseBuffer = StringBuffer();

      await for (final String responseChunk in responseStream) {
        responseBuffer.write(responseChunk);
      }

      return responseBuffer.toString();
    } catch (e) {
      debugPrint('Error generating response: $e');
      throw Exception('Failed to generate response: $e');
    }
  }

  Future<String> generateResponseStream(
    String input,
    Function(String) onChunk,
  ) async {
    if (!_isInitialized || _engine == null) {
      throw StateError(
        'MediaPipe GenAI service not initialized. Call initialize() first.',
      );
    }

    try {
      final Stream<String> responseStream = _engine!.generateResponse(input);
      final StringBuffer responseBuffer = StringBuffer();

      await for (final String responseChunk in responseStream) {
        responseBuffer.write(responseChunk);
        onChunk(responseChunk);
      }

      return responseBuffer.toString();
    } catch (e) {
      debugPrint('Error generating response stream: $e');
      throw Exception('Failed to generate response stream: $e');
    }
  }

  Future<String> _getModelPath() async {
    try {
      // For Flutter assets, we need to copy the model to a temporary directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/models');

      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final modelFile = File('${modelDir.path}/gemma3-270m-it-q8.task');

      // Check if model already exists
      if (!await modelFile.exists()) {
        // In a real app, you would copy the asset to the file system
        // For now, we'll use the asset path directly
        // This might need to be implemented based on your specific setup
        debugPrint('Model file not found at ${modelFile.path}');
        debugPrint('Using asset path directly');
        return 'assets/models/gemma3-270m-it-q8.task';
      }

      return modelFile.path;
    } catch (e) {
      debugPrint('Error getting model path: $e');
      // Fallback to asset path
      return 'assets/models/gemma3-270m-it-q8.task';
    }
  }

  void dispose() {
    _engine = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}

// Helper function for backward compatibility
Future<String> getModelPath() async {
  return await MediaPipeLocalGenAIService.instance._getModelPath();
}

// Example usage function
Future<void> exampleUsage() async {
  final service = MediaPipeLocalGenAIService.instance;

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
