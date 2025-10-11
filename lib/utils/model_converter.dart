import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utility for converting between different model formats
class ModelConverter {
  /// Convert MediaPipe .task model to .tflite format
  /// 
  /// This is a placeholder implementation. In a real scenario, you would need
  /// to use MediaPipe's conversion tools or implement the conversion logic.
  static Future<String?> convertTaskToTflite(String taskModelPath) async {
    try {
      debugPrint('Attempting to convert $taskModelPath to .tflite format...');
      
      // Read the task model file
      final taskFile = File(taskModelPath);
      if (!await taskFile.exists()) {
        debugPrint('Task model file not found: $taskModelPath');
        return null;
      }
      
      // For now, we'll just copy the file with .tflite extension
      // In a real implementation, you would need to:
      // 1. Parse the MediaPipe task model format
      // 2. Extract the underlying TensorFlow Lite model
      // 3. Save it in standard .tflite format
      
      final appDocDir = await getApplicationDocumentsDirectory();
      final tflitePath = '${appDocDir.path}/gemma3-270m-it-q8.tflite';
      
      // Copy the file
      await taskFile.copy(tflitePath);
      
      debugPrint('Model copied to: $tflitePath');
      return tflitePath;
      
    } catch (e) {
      debugPrint('Error converting model: $e');
      return null;
    }
  }
  
  /// Check if a model file exists and is accessible
  static Future<bool> isModelAccessible(String modelPath) async {
    try {
      final file = File(modelPath);
      return await file.exists() && await file.length() > 0;
    } catch (e) {
      debugPrint('Error checking model accessibility: $e');
      return false;
    }
  }
  
  /// Get model information
  static Future<String> getModelInfo(String modelPath) async {
    try {
      final file = File(modelPath);
      if (!await file.exists()) {
        return 'Model not found: $modelPath';
      }
      
      final size = await file.length();
      final lastModified = await file.lastModified();
      
      return '''
Model Path: $modelPath
File Size: ${_formatBytes(size)}
Last Modified: $lastModified
Status: Accessible
''';
    } catch (e) {
      return 'Error getting model info: $e';
    }
  }
  
  /// Format bytes to human readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}