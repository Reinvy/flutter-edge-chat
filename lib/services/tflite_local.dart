import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' as services;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/model_converter.dart';

/// TFLite Local Service Implementation
///
/// This service provides local AI inference using TFLite models.
/// It replaces the MediaPipe GenAI service functionality with a TFLite-based implementation.
class TFLiteLocalService {
  static TFLiteLocalService? _instance;
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _useGpu = false;

  // Model configuration
  // static const String _modelName = 'gemma3-270m-it-q8';
  static const String _modelName = 'Llama-3.2-1B-Instruct_seq128_q8_ekv1280';
  static const String _modelExtension = '.task';
  static const String _tfliteExtension = '.tflite';

  TFLiteLocalService._internal();

  /// Singleton instance getter
  static TFLiteLocalService get instance {
    _instance ??= TFLiteLocalService._internal();
    return _instance!;
  }

  /// Initialize the TFLite service
  ///
  /// [useGpu] - Whether to use GPU delegate for inference (if available)
  /// [retryCount] - Number of retry attempts for initialization
  /// Returns true if initialization was successful
  Future<bool> initialize({bool useGpu = false, int retryCount = 3}) async {
    if (_isInitialized) return true;

    int attempt = 0;
    while (attempt < retryCount) {
      attempt++;
      try {
        debugPrint('TFLite initialization attempt $attempt/$retryCount');
        _useGpu = useGpu;

        // Load the model with retry logic
        final modelPath = await getModelPathWithRetry(maxRetries: 3);
        if (modelPath.isEmpty) {
          throw Exception('Model file not found after $retryCount attempts');
        }

        // Create interpreter options
        final options = InterpreterOptions();

        // Try to use GPU delegate if requested and available
        if (useGpu) {
          try {
            if (Platform.isAndroid) {
              final gpuDelegate = GpuDelegateV2();
              options.addDelegate(gpuDelegate);
            } else if (Platform.isIOS) {
              final gpuDelegate = GpuDelegate();
              options.addDelegate(gpuDelegate);
            }
          } catch (e) {
            debugPrint('GPU delegate not available, using CPU: $e');
          }
        }

        // Load the interpreter with error handling
        await _loadInterpreterWithRetry(File(modelPath), options, retryCount: 2);

        if (_interpreter == null) {
          throw Exception('Failed to load interpreter after $retryCount attempts');
        }

        _isInitialized = true;
        debugPrint('TFLite service initialized successfully with ${useGpu ? 'GPU' : 'CPU'} delegate');
        return true;
      } catch (e) {
        debugPrint('TFLite initialization attempt $attempt failed: $e');
        if (attempt >= retryCount) {
          debugPrint('Failed to initialize TFLite service after $retryCount attempts: $e');
          _isInitialized = false;
          return false;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
    
    _isInitialized = false;
    return false;
  }

  /// Load interpreter with retry logic
  Future<void> _loadInterpreterWithRetry(File modelFile, InterpreterOptions options, {int retryCount = 3}) async {
    int attempt = 0;
    while (attempt < retryCount) {
      attempt++;
      try {
        debugPrint('Loading interpreter attempt $attempt/$retryCount');
        _interpreter = Interpreter.fromFile(modelFile, options: options);
        return;
      } catch (e) {
        debugPrint('Interpreter loading attempt $attempt failed: $e');
        if (attempt >= retryCount) {
          throw Exception('Failed to load interpreter after $retryCount attempts: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Get model path with retry logic
  Future<String> getModelPathWithRetry({int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        debugPrint('Getting model path attempt $attempt/$maxRetries');
        return await getModelPath();
      } catch (e) {
        debugPrint('Model path attempt $attempt failed: $e');
        if (attempt >= maxRetries) {
          throw Exception('Failed to get model path after $maxRetries attempts: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
    return '';
  }

  /// Get the model path from assets
  Future<String> getModelPath() async {
    try {
      debugPrint('Getting model path...');

      // First try to load the .tflite format (preferred)
      final tfliteModelPath = 'assets/models/$_modelName$_tfliteExtension';
      final tfliteExists = await _checkAssetExists(tfliteModelPath);

      if (tfliteExists) {
        debugPrint('Found .tflite model in assets');
        return await _copyModelToAppDir(tfliteModelPath, _modelName + _tfliteExtension);
      }

      // Fallback to .task format (MediaPipe)
      final taskModelPath = 'assets/models/$_modelName$_modelExtension';
      final taskExists = await _checkAssetExists(taskModelPath);

      if (taskExists) {
        debugPrint('Found .task model in assets, attempting conversion...');

        // Copy task model first
        final taskCopyPath = await _copyModelToAppDir(taskModelPath, _modelName + _modelExtension);

        // Try to convert to .tflite
        final tfliteConvertedPath = await ModelConverter.convertTaskToTflite(taskCopyPath);

        if (tfliteConvertedPath != null && await File(tfliteConvertedPath).exists()) {
          debugPrint('Successfully converted .task to .tflite');
          return tfliteConvertedPath;
        } else {
          debugPrint('Conversion failed, using .task model directly');
          return taskCopyPath;
        }
      }

      throw Exception('Neither .task nor .tflite model found in assets');
    } catch (e) {
      debugPrint('Error getting model path: $e');
      throw Exception('Failed to get model path: $e');
    }
  }

  /// Check if asset exists with proper error handling
  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await services.rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Copy model file to app directory with retry logic
  Future<String> _copyModelToAppDir(String assetPath, String fileName) async {
    int attempt = 0;
    const maxAttempts = 3;
    
    while (attempt < maxAttempts) {
      attempt++;
      try {
        debugPrint('Copying model to app directory (attempt $attempt/$maxAttempts)...');
        
        final appDocDir = await getApplicationDocumentsDirectory();
        final targetPath = '${appDocDir.path}/$fileName';

        // Check if file already exists and is accessible
        final file = File(targetPath);
        if (await file.exists() && await file.length() > 0) {
          // Verify the file is accessible by reading a small portion
          await file.openRead().first;
          debugPrint('Model already exists and is accessible at: $targetPath');
          return targetPath;
        }

        // Copy from assets with timeout
        final byteData = await _loadAssetWithTimeout(assetPath);
        final bytes = byteData.buffer.asUint8List();
        
        // Ensure directory exists
        await file.create(recursive: true);
        
        // Write bytes asynchronously
        await file.writeAsBytes(bytes);

        // Verify the file was written correctly
        if (await file.exists() && await file.length() > 0) {
          debugPrint('Model successfully copied to: $targetPath');
          return targetPath;
        } else {
          throw Exception('Failed to verify copied model file');
        }
        
      } catch (e) {
        debugPrint('Error copying model on attempt $attempt: $e');
        
        if (attempt >= maxAttempts) {
          throw Exception('Failed to copy model after $maxAttempts attempts: $e');
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
        
        // Clean up partially written file if it exists
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final targetPath = '${appDocDir.path}/$fileName';
          final file = File(targetPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('Cleaned up partially written model file');
          }
        } catch (cleanupError) {
          debugPrint('Error cleaning up partially written model: $cleanupError');
        }
      }
    }
    
    throw Exception('Failed to copy model after all attempts');
  }

  /// Load asset with timeout to prevent hanging
  Future<services.ByteData> _loadAssetWithTimeout(String assetPath) async {
    try {
      return await services.rootBundle.load(assetPath).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Asset loading timeout'),
      );
    } catch (e) {
      throw Exception('Failed to load asset: $e');
    }
  }

  /// Generate a response from the model
  ///
  /// [input] - The input text to process
  /// [retryCount] - Number of retry attempts for response generation
  /// Returns the generated response text
  Future<String> generateResponse(String input, {int retryCount = 2}) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('TFLite service not initialized');
    }

    int attempt = 0;
    while (attempt < retryCount) {
      attempt++;
      try {
        debugPrint('Generating response attempt $attempt/$retryCount');
        
        // Preprocess input
        final processedInput = _preprocessInput(input);

        // Run inference
        final output = await _runInference(processedInput);

        // Postprocess output
        final response = _postprocessOutput(output);

        return response;
      } catch (e) {
        debugPrint('Response generation attempt $attempt failed: $e');
        if (attempt >= retryCount) {
          debugPrint('Failed to generate response after $retryCount attempts: $e');
          throw Exception('Failed to generate response: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    
    throw Exception('Failed to generate response after $retryCount attempts');
  }

  /// Generate response with streaming support
  ///
  /// [input] - The input text to process
  /// [onChunk] - Callback for streaming response chunks
  /// [retryCount] - Number of retry attempts for response generation
  /// Returns the complete response text
  Future<String> generateResponseStream(String input, Function(String) onChunk, {int retryCount = 2}) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('TFLite service not initialized');
    }

    int attempt = 0;
    while (attempt < retryCount) {
      attempt++;
      try {
        debugPrint('Generating streaming response attempt $attempt/$retryCount');
        
        // For streaming, we'll simulate it by breaking down the response
        // In a real implementation, this would use the model's streaming capabilities
        final fullResponse = await generateResponse(input, retryCount: retryCount);

        // Simulate streaming by sending chunks
        final chunks = _splitIntoChunks(fullResponse);
        for (final chunk in chunks) {
          onChunk(chunk);
          await Future.delayed(const Duration(milliseconds: 100)); // Simulate streaming delay
        }

        return fullResponse;
      } catch (e) {
        debugPrint('Streaming response generation attempt $attempt failed: $e');
        if (attempt >= retryCount) {
          debugPrint('Failed to generate streaming response after $retryCount attempts: $e');
          throw Exception('Failed to generate streaming response: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    
    throw Exception('Failed to generate streaming response after $retryCount attempts');
  }

  /// Preprocess input text for model inference
  Uint8List _preprocessInput(String input) {
    // This is a simplified preprocessing
    // In a real implementation, this would convert text to tensor format
    // specific to the model requirements

    // Convert string to bytes (UTF-8 encoded)
    final bytes = input.codeUnits;

    // Pad or truncate to expected input size
    // This is a placeholder - actual implementation depends on model
    const inputSize = 512; // Example input size
    final paddedBytes = Uint8List(inputSize);

    for (int i = 0; i < min(bytes.length, inputSize); i++) {
      paddedBytes[i] = bytes[i];
    }

    return paddedBytes;
  }

  /// Run model inference
  Future<Uint8List> _runInference(Uint8List input) async {
    if (_interpreter == null) {
      throw Exception('Interpreter not initialized');
    }

    // Prepare input and output tensors
    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    if (inputTensors.isEmpty || outputTensors.isEmpty) {
      throw Exception('Invalid model tensor configuration');
    }

    // Create input buffer
    final inputBuffer = input.buffer;

    // Create output buffer
    final outputShape = outputTensors[0].shape;
    final outputSize = outputShape.reduce((a, b) => a * b);
    final outputBuffer = Uint8List(outputSize);

    // Run inference
    try {
      // Use the correct API for tflite_flutter
      _interpreter!.run(inputBuffer, outputBuffer);

      return outputBuffer;
    } catch (e) {
      debugPrint('Inference error: $e');
      throw Exception('Inference failed: $e');
    }
  }

  /// Postprocess model output
  String _postprocessOutput(Uint8List output) {
    // This is a simplified postprocessing
    // In a real implementation, this would convert model output to text

    // Convert bytes to string (UTF-8 decoded)
    try {
      final text = String.fromCharCodes(output.where((byte) => byte >= 32 && byte <= 126));
      return text.isNotEmpty ? text : 'No response generated';
    } catch (e) {
      debugPrint('Error postprocessing output: $e');
      return 'Error processing response';
    }
  }

  /// Split response into chunks for streaming
  List<String> _splitIntoChunks(String text) {
    // Simple chunking by sentences
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isNotEmpty) {
        chunks.add(sentence + (i < sentences.length - 1 ? '.' : ''));
      }
    }

    return chunks.isNotEmpty ? chunks : ['No response'];
  }

  /// Dispose resources
  void dispose() {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isInitialized = false;
      debugPrint('TFLite service disposed');
    } catch (e) {
      debugPrint('Error disposing TFLite service: $e');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if GPU is being used
  bool get useGpu => _useGpu;

  /// Get initialization status with details
  String getInitializationStatus() {
    if (!_isInitialized) {
      return 'Not Initialized';
    }
    return 'Initialized (${_useGpu ? 'GPU' : 'CPU'})';
  }

  /// Check if service is ready for inference
  bool get isReady => _isInitialized && _interpreter != null;
}
