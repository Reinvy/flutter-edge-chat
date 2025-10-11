import 'package:flutter_gemma/flutter_gemma.dart';

class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  FlutterGemmaPlugin? _gemma;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<bool> initializeModel() async {
    try {
      _errorMessage = null;

      // Initialize the plugin
      _gemma = FlutterGemmaPlugin.instance;

      // Try different model paths in order of preference
      final modelPath = 'models/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

      bool modelLoaded = false;
      String? lastError;

      try {
        // Use the new FlutterGemma API
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromAsset(modelPath).install();

        // Try to create a model
        _model = await _gemma!.createModel(
          modelType: ModelType.gemmaIt,
          preferredBackend: PreferredBackend.cpu,
          maxTokens: 2048,
        );

        // Create chat session
        // _chat = await _model!.createChat(temperature: 0.8, randomSeed: 1, topK: 40, topP: 0.9);
        _chat = await _model!.createChat(temperature: 0.7, randomSeed: 42, topK: 40, topP: 0.9);

        _isInitialized = true;
        modelLoaded = true;
        print('Model initialized successfully with: $modelPath');
      } catch (e) {
        lastError = 'Failed to load $modelPath: ${e.toString()}';
        print('Model loading error for $modelPath: $e');
        // Continue to next model
        _model = null;
        _chat = null;
      }

      if (!modelLoaded) {
        _errorMessage = 'Failed to load any available model. Last error: $lastError';
        print('All model loading attempts failed');
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize model: ${e.toString()}';
      print('Model initialization error: $e');
      return false;
    }
  }

  Future<String> generateResponse(String userMessage) async {
    if (!_isInitialized || _chat == null) {
      throw Exception('Model not initialized');
    }

    try {
      // Add user message
      await _chat!.addQueryChunk(Message.text(text: userMessage, isUser: true));

      // Generate response
      String response = '';
      await for (final responseChunk in _chat!.generateChatResponseAsync()) {
        if (responseChunk is TextResponse) {
          response += responseChunk.token;
        }
      }

      print(
        'Generated response: ${response.substring(0, response.length < 100 ? response.length : 100)}...',
      );
      return response;
    } catch (e) {
      _errorMessage = 'Failed to generate response: ${e.toString()}';
      print('Response generation error: $e');
      throw Exception('Failed to generate response: ${e.toString()}');
    }
  }

  Future<void> dispose() async {
    try {
      _chat = null;
      _model = null;
      _gemma = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing model: $e');
    }
  }
}
