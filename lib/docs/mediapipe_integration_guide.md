# MediaPipe GenAI Integration Guide

This guide explains how to integrate MediaPipe GenAI with the Gemma 3B model in your Flutter application.

## Overview

The MediaPipe GenAI service provides a simple interface to run local language models on mobile devices. This implementation uses the `gemma3-270m-it-q8.task` model for text generation.

## Architecture

### Core Components

1. **MediaPipeGenAIService** (`lib/services/mediapipe.dart`)

   - Main service class for MediaPipe GenAI operations
   - Handles model initialization and inference
   - Supports both CPU and GPU execution

2. **MediaPipeHelper** (`lib/helpers/mediapipe_helper.dart`)

   - Convenience wrapper for common operations
   - Provides simplified API for initialization and inference
   - Includes error handling and logging

3. **MediaPipeUsageExample** (`lib/examples/mediapipe_usage_example.dart`)
   - Example implementations for common use cases
   - Chat functionality with conversation history
   - Streaming and non-streaming response generation

## Setup

### 1. Dependencies

Ensure the following dependencies are added to `pubspec.yaml`:

```yaml
dependencies:
  mediapipe_core: ^0.10.0
  mediapipe_genai: ^0.10.0
  google_generative_ai: ^0.4.3
  path_provider: ^2.1.1
```

### 2. Assets

Add the model file to your assets:

```yaml
flutter:
  assets:
    - assets/models/gemma3-270m-it-q8.task
```

## Usage

### Basic Initialization

```dart
import 'package:your_app/helpers/mediapipe_helper.dart';

// Initialize the service
final initialized = await MediaPipeHelper.initialize(useGpu: false);
if (initialized) {
  print('MediaPipe GenAI is ready!');
}
```

### Generate Response

```dart
// Simple response generation
String response = await MediaPipeHelper.generateResponse('Hello, world!');
print(response);

// Streaming response with callback
await MediaPipeHelper.generateResponseStream(
  'What is artificial intelligence?',
  (chunk) {
    print('Chunk: $chunk');
  },
  onComplete: () {
    print('Response completed');
  },
);
```

### Chat Functionality

```dart
import 'package:your_app/examples/mediapipe_usage_example.dart';

// Chat with conversation history
List<String> history = [
  'User: What is your name?',
  'Assistant: I am an AI assistant powered by Gemma.'
];

String response = await MediaPipeUsageExample.chatWithAI(
  'How can I help you today?',
  history,
  onChunk: (chunk) {
    // Update UI with each chunk
  },
);
```

### Error Handling

```dart
try {
  String response = await MediaPipeHelper.generateResponse('Your prompt');
  print(response);
} catch (e) {
  print('Error: $e');
  // Handle error appropriately
}
```

## Configuration

### Model Parameters

The service uses the following default parameters:

- `maxTokens`: 512
- `temperature`: 0.7
- `topK`: 40
- `sequenceBatchSize`: 1

### GPU vs CPU

- **CPU**: Slower but compatible with all devices
- **GPU**: Faster but requires GPU support

Choose based on your target device capabilities:

```dart
// CPU (recommended for most devices)
await MediaPipeHelper.initialize(useGpu: false);

// GPU (for devices with GPU support)
await MediaPipeHelper.initialize(useGpu: true);
```

## Performance Considerations

1. **Model Loading**: The model takes time to load on first use
2. **Memory Usage**: The model requires significant memory (~1GB)
3. **Battery Usage**: GPU mode consumes more battery
4. **Response Time**: First response is slower due to model warmup

## Best Practices

1. **Lazy Initialization**: Initialize the service when needed, not at app startup
2. **Resource Management**: Call `dispose()` when the service is no longer needed
3. **Error Handling**: Always wrap API calls in try-catch blocks
4. **Streaming**: Use streaming for real-time UI updates
5. **Conversation Context**: Maintain conversation history for coherent responses

## Troubleshooting

### Common Issues

1. **Initialization Failed**

   - Check if the model file exists in assets
   - Ensure proper permissions for file access
   - Verify device compatibility

2. **Slow Performance**

   - Try GPU mode if available
   - Reduce response length
   - Optimize input prompts

3. **Memory Issues**
   - Close other memory-intensive apps
   - Use smaller model if available
   - Monitor memory usage

### Debug Information

```dart
// Get system information
String info = await MediaPipeHelper.getModelInfo();
print(info);

// Check initialization status
bool isReady = MediaPipeHelper.isInitialized;
print('Service ready: $isReady');
```

## Example Integration

See `lib/examples/mediapipe_usage_example.dart` for a complete implementation example that demonstrates:

- Service initialization
- Response generation
- Chat functionality
- Error handling
- Resource cleanup
