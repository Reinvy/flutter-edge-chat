# TFLite Local AI Integration Guide

> **Note**: This guide has been updated to reflect the migration from MediaPipe GenAI to TFLite-based local AI inference. The implementation now uses TensorFlow Lite for on-device model execution.

## Overview

This guide explains how to integrate TFLite-based local AI inference with the Gemma 3B model in a Flutter application. The TFLite service provides a simple interface to run local language models on mobile devices using the `gemma3-270m-it-q8.task` or `.tflite` model formats.

## Architecture

The implementation follows a layered architecture:

- **TFLiteLocalService** (`lib/services/tflite_local.dart`) - Core TFLite inference engine
- **MediaPipeLocalGenAIService** (`lib/services/mediapipe_local.dart`) - Wrapper for backward compatibility
- **MediaPipeGenAIService** (`lib/services/mediapipe.dart`) - Main service with cloud fallback support
- **MediaPipeHelper** (`lib/helpers/mediapipe_helper.dart`) - Convenience methods and helper functions
- **ModelConverter** (`lib/utils/model_converter.dart`) - Utility for model format conversion

## Prerequisites

### Dependencies

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.11.0
  path_provider: ^2.1.1
  google_generative_ai: ^0.4.3  # Optional, for cloud fallback
```

### Model Files

Place your model files in the `assets/models/` directory:

```yaml
flutter:
  assets:
    - assets/models/
    - assets/models/gemma3-270m-it-q8.task  # MediaPipe format
    - assets/models/gemma3-270m-it-q8.tflite  # TFLite format (preferred)
```

## Quick Start

### 1. Initialize the Service

```dart
import 'package:your_app/helpers/mediapipe_helper.dart';

// Basic initialization
await MediaPipeHelper.initialize(useGpu: false);

// With cloud fallback (when implemented)
await MediaPipeHelper.initialize(
  useGpu: true,
  useCloudFallback: true,
);
```

### 2. Generate Responses

```dart
// Simple response
String response = await MediaPipeHelper.generateResponse('Hello, world!');

// Streaming response
await MediaPipeHelper.generateResponseStream(
  'What is artificial intelligence?',
  (chunk) {
    print('Chunk: $chunk');
  },
  onComplete: () => print('Response completed'),
  onError: (error) => print('Error: $error'),
);
```

### 3. Check Service Status

```dart
// Check if initialized
if (MediaPipeHelper.isInitialized) {
  print('Service is ready');
}

// Get detailed status
String status = MediaPipeHelper.getDetailedServiceStatus();
print('Status: $status');

// Get model information
String modelInfo = await MediaPipeHelper.getModelInfo();
print('Model: $modelInfo');
```

## Advanced Usage

### Direct TFLite Service Usage

For more control, you can use the TFLite service directly:

```dart
import 'package:your_app/services/tflite_local.dart';

// Get singleton instance
final tfliteService = TFLiteLocalService.instance;

// Initialize with GPU support
await tfliteService.initialize(useGpu: true);

// Generate response
String response = await tfliteService.generateResponse('Your input text');

// Streaming response
await tfliteService.generateResponseStream(
  'Your input text',
  (chunk) => print('Chunk: $chunk'),
);

// Cleanup
tfliteService.dispose();
```

### Model Format Support

The service supports both `.task` (MediaPipe) and `.tflite` formats:

1. **TFLite Format (Preferred)**: Direct inference with better performance
2. **MediaPipe Task Format**: Automatic conversion to TFLite when possible

```dart
// Check model format
String modelPath = await tfliteService.getModelPath();
if (modelPath.endsWith('.tflite')) {
  print('Using TFLite model');
} else if (modelPath.endsWith('.task')) {
  print('Using MediaPipe task model');
}
```

## Configuration Options

### GPU Acceleration

Enable GPU acceleration for better performance on supported devices:

```dart
// Check GPU availability
final useGpu = Platform.isAndroid || Platform.isIOS;

// Initialize with GPU
await MediaPipeHelper.initialize(useGpu: useGpu);
```

### Model Management

The service automatically handles model loading and caching:

```dart
// Get model information
String modelInfo = await MediaPipeHelper.getModelInfo();

// Check model accessibility
bool isAccessible = await ModelConverter.isModelAccessible(modelPath);
```

## Error Handling

### Common Errors

```dart
try {
  await MediaPipeHelper.initialize(useGpu: false);
} catch (e) {
  if (e.toString().contains('Model file not found')) {
    print('Model file missing. Check assets/models/ directory');
  } else if (e.toString().contains('GPU delegate not available')) {
    print('GPU acceleration not available, using CPU');
  } else {
    print('Initialization failed: $e');
  }
}
```

### Graceful Degradation

The service implements graceful degradation:

1. **GPU fails**: Automatically falls back to CPU
2. **TFLite model missing**: Attempts to use `.task` format
3. **Model conversion fails**: Uses original `.task` model
4. **Local service fails**: Falls back to cloud service (when implemented)

## Troubleshooting

### Model Loading Issues

**Problem**: "Model file not found"

**Solutions**:
1. Verify model files are in `assets/models/` directory
2. Check `pubspec.yaml` assets configuration
3. Ensure model files are included in build

**Problem**: "Failed to load interpreter"

**Solutions**:
1. Check model format compatibility
2. Verify model file integrity
3. Try CPU fallback if GPU fails

### Performance Issues

**Problem**: Slow inference

**Solutions**:
1. Enable GPU acceleration: `initialize(useGpu: true)`
2. Use TFLite format instead of `.task`
3. Optimize model size and complexity

**Problem**: High memory usage

**Solutions**:
1. Reduce model batch size
2. Implement model quantization
3. Use smaller model variants

### Platform-Specific Issues

**Android**:
- Add GPU delegate support in `AndroidManifest.xml`
- Ensure OpenGL ES 3.0+ support
- Handle large model files with care

**iOS**:
- Enable Metal support for GPU acceleration
- Handle model file permissions
- Optimize for iOS memory constraints

## Migration from MediaPipe

### API Compatibility

The new TFLite implementation maintains API compatibility:

```dart
// Old MediaPipe API (still works)
await MediaPipeHelper.initialize(useGpu: false);
String response = await MediaPipeHelper.generateResponse('Hello');

// New TFLite API (recommended)
await TFLiteLocalService.instance.initialize(useGpu: false);
String response = await TFLiteLocalService.instance.generateResponse('Hello');
```

### Key Differences

1. **Model Format**: TFLite prefers `.tflite` format over `.task`
2. **Performance**: Better inference speed and memory efficiency
3. **GPU Support**: More robust GPU acceleration implementation
4. **Error Handling**: More detailed error messages and recovery options

### Migration Steps

1. **Update Dependencies**: Replace MediaPipe dependencies with TFLite
2. **Model Conversion**: Convert `.task` models to `.tflite` format
3. **GPU Configuration**: Update GPU initialization code
4. **Error Handling**: Enhance error handling for TFLite-specific issues
5. **Testing**: Test thoroughly on target devices

## Best Practices

### Model Management

1. **Use TFLite Format**: Preferred for better performance
2. **Model Quantization**: Use quantized models for mobile deployment
3. **Model Caching**: Implement proper model caching strategies
4. **Version Control**: Track model versions and updates

### Performance Optimization

1. **GPU Acceleration**: Enable GPU when available
2. **Batch Processing**: Implement batch processing for multiple inputs
3. **Memory Management**: Properly dispose of resources
4. **Background Processing**: Use isolates for heavy computations

### Error Handling

1. **Graceful Degradation**: Implement fallback mechanisms
2. **User Feedback**: Provide clear error messages
3. **Logging**: Implement comprehensive logging
4. **Recovery**: Implement automatic recovery where possible

## Future Enhancements

### Planned Features

1. **Cloud Fallback**: Integration with cloud AI services
2. **Model Management**: Automatic model updates and versioning
3. **Performance Monitoring**: Built-in performance metrics
4. **Custom Models**: Support for custom model architectures

### Integration Opportunities

1. **Multi-Modal AI**: Integration with image and audio models
2. **Edge Computing**: Advanced edge deployment strategies
3. **Model Compression**: Advanced model optimization techniques
4. **Distributed Inference**: Multi-device inference coordination

## References

- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Flutter Asset Management](https://flutter.dev/docs/development/ui/assets)
- [Mobile GPU Acceleration](https://www.tensorflow.org/lite/performance/gpu)
- [Flutter Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)

For more information about the implementation, refer to the source code in the `lib/` directory and the example usage in `lib/examples/mediapipe_usage_example.dart`.
