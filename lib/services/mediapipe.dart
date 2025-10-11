import 'package:flutter/foundation.dart';
import 'mediapipe_local.dart';

/// MediaPipe GenAI Service
///
/// This service now uses TFLiteLocalService as the primary implementation
/// with optional cloud fallback capabilities.
class MediaPipeGenAIService {
  static MediaPipeGenAIService? _instance;
  MediaPipeLocalGenAIService? _localService;
  bool _useCloudFallback = false;

  MediaPipeGenAIService._internal();

  static MediaPipeGenAIService get instance {
    _instance ??= MediaPipeGenAIService._internal();
    return _instance!;
  }

  /// Initialize the service with TFLiteLocalService as primary
  ///
  /// [useGpu] - Whether to use GPU delegate for inference (if available)
  /// [useCloudFallback] - Whether to enable cloud service fallback
  /// [retryCount] - Number of retry attempts for initialization
  /// Returns true if initialization was successful
  Future<bool> initialize({
    bool useGpu = false,
    bool useCloudFallback = false,
    int retryCount = 3,
  }) async {
    int attempt = 0;
    while (attempt < retryCount) {
      attempt++;
      try {
        debugPrint('MediaPipe GenAI Service initialization attempt $attempt/$retryCount');
        _useCloudFallback = useCloudFallback;
        
        // Initialize local TFLite service
        _localService = MediaPipeLocalGenAIService.instance;
        final localInitialized = await _localService!.initialize(useGpu: useGpu);
        
        if (localInitialized) {
          debugPrint('MediaPipe GenAI Service initialized with TFLiteLocalService');
          return true;
        } else {
          debugPrint('Failed to initialize TFLiteLocalService on attempt $attempt');
          
          // Check for specific error messages
          if (_isNativeLibraryError()) {
            debugPrint('Native library error detected on attempt $attempt');
            if (attempt >= retryCount) {
              throw Exception('Failed to load native library (libmbrainSDK). Please check device compatibility.');
            }
          }
          
          // If cloud fallback is enabled, try cloud service
          if (_useCloudFallback) {
            debugPrint('Attempting cloud fallback...');
            // TODO: Implement cloud service initialization
            // For now, return false as cloud service is not implemented
            return false;
          }
          
          if (attempt >= retryCount) {
            return false;
          }
          
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      } catch (e) {
        debugPrint('Error initializing MediaPipe GenAI Service on attempt $attempt: $e');
        
        // Check for specific error messages
        if (e.toString().contains('libmbrainSDK') ||
            e.toString().contains('native library') ||
            e.toString().contains('dlopen failed') ||
            e.toString().contains('library not found')) {
          debugPrint('Native library error detected: $e');
          if (attempt >= retryCount) {
            throw Exception('Failed to load native library. Please check device compatibility and ensure all required libraries are properly installed.');
          }
        }
        
        // If cloud fallback is enabled, try cloud service
        if (_useCloudFallback) {
          debugPrint('Attempting cloud fallback due to initialization error...');
          // TODO: Implement cloud service initialization
          return false;
        }
        
        if (attempt >= retryCount) {
          return false;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
    
    return false;
  }

  /// Check if the error is related to native library loading
  bool _isNativeLibraryError() {
    // This is a simplified check - in a real app you might want more sophisticated error detection
    return false; // Placeholder for actual error detection logic
  }

  /// Get detailed initialization error information
  String getInitializationError() {
    if (_localService == null) {
      return 'Service not initialized';
    }
    
    if (!_localService!.isInitialized) {
      return 'Failed to initialize local AI service';
    }
    
    return 'Unknown initialization error';
  }

  /// Generate a response from the model
  ///
  /// [input] - The input text to process
  /// Returns the generated response text
  Future<String> generateResponse(String input) async {
    try {
      // Try local service first
      if (_localService != null && _localService!.isInitialized) {
        debugPrint('Generating response using TFLiteLocalService');
        return await _localService!.generateResponse(input);
      }
      
      // If cloud fallback is enabled, try cloud service
      if (_useCloudFallback) {
        debugPrint('Attempting cloud fallback for response generation...');
        // TODO: Implement cloud service response generation
        throw Exception('Cloud fallback not implemented');
      }
      
      throw Exception('No AI service available');
    } catch (e) {
      debugPrint('Error generating response: $e');
      
      // If cloud fallback is enabled, try cloud service
      if (_useCloudFallback) {
        debugPrint('Attempting cloud fallback due to error...');
        // TODO: Implement cloud service response generation
        throw Exception('Cloud fallback not implemented: $e');
      }
      
      throw Exception('Failed to generate response: $e');
    }
  }

  /// Generate response with streaming support
  ///
  /// [input] - The input text to process
  /// [onChunk] - Callback for streaming response chunks
  /// Returns the complete response text
  Future<String> generateResponseStream(
    String input,
    Function(String) onChunk,
  ) async {
    try {
      // Try local service first
      if (_localService != null && _localService!.isInitialized) {
        debugPrint('Generating streaming response using TFLiteLocalService');
        return await _localService!.generateResponseStream(input, onChunk);
      }
      
      // If cloud fallback is enabled, try cloud service
      if (_useCloudFallback) {
        debugPrint('Attempting cloud fallback for streaming response...');
        // TODO: Implement cloud service streaming response
        throw Exception('Cloud fallback not implemented');
      }
      
      throw Exception('No AI service available');
    } catch (e) {
      debugPrint('Error generating streaming response: $e');
      
      // If cloud fallback is enabled, try cloud service
      if (_useCloudFallback) {
        debugPrint('Attempting cloud fallback due to error...');
        // TODO: Implement cloud service streaming response
        throw Exception('Cloud fallback not implemented: $e');
      }
      
      throw Exception('Failed to generate streaming response: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      debugPrint('Disposing MediaPipe GenAI Service');
      _localService?.dispose();
      _localService = null;
    } catch (e) {
      debugPrint('Error disposing MediaPipe GenAI Service: $e');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _localService?.isInitialized ?? false;

  /// Get model path for backward compatibility
  Future<String> getModelPath() async {
    try {
      return await _localService?.getModelPath() ?? '';
    } catch (e) {
      debugPrint('Error getting model path: $e');
      return '';
    }
  }

  /// Get model information
  Future<String> getModelInfo() async {
    try {
      return await _localService?.getModelInfo() ??
        'Model: Not Available\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
    } catch (e) {
      debugPrint('Error getting model info: $e');
      return 'Model: Error\nStatus: ${isInitialized ? "Initialized" : "Not Initialized"}';
    }
  }

  /// Check if cloud fallback is enabled
  bool get useCloudFallback => _useCloudFallback;

  /// Enable or disable cloud fallback
  set useCloudFallback(bool enabled) {
    _useCloudFallback = enabled;
  }
}

// Helper function for backward compatibility
Future<String> getModelPath() async {
  return await MediaPipeGenAIService.instance.getModelPath();
}

// Example usage function
Future<void> exampleUsage() async {
  try {
    debugPrint('MediaPipe GenAI Service Example Usage with TFLiteLocalService');

    // Initialize the service
    final initialized = await MediaPipeGenAIService.instance.initialize(
      useGpu: false,
      useCloudFallback: true, // Enable cloud fallback
    );
    
    if (!initialized) {
      debugPrint('Failed to initialize service');
      return;
    }

    // Generate a response
    final response = await MediaPipeGenAIService.instance.generateResponse(
      'Hello, how are you?',
    );
    debugPrint('Response: $response');

    // Generate streaming response
    final chunks = <String>[];
    await MediaPipeGenAIService.instance.generateResponseStream(
      'Tell me about artificial intelligence',
      (chunk) {
        chunks.add(chunk);
        debugPrint('Chunk: $chunk');
      },
    );

    debugPrint('Full streaming response: ${chunks.join()}');

    // Cleanup
    MediaPipeGenAIService.instance.dispose();
  } catch (e) {
    debugPrint('Error in example usage: $e');
  }
}
