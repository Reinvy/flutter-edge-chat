import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/mediapipe_helper.dart';
import '../utils/initialization_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // State management
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _responseText = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAIServiceInitialized = false;
  String _aiServiceStatus = 'Initializing...';
  bool _useGpu = false; // GPU option for initialization

  // Use InitializationManager for centralized state management
  final InitializationManager _initManager = InitializationManager.instance;
  late StreamSubscription<InitializationState> _stateSubscription;
  late StreamSubscription<InitializationProgress> _progressSubscription;

  @override
  void initState() {
    super.initState();
    _setupInitializationStreams();
    _initializeAIService();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Cleanup AI service using MediaPipeHelper
    MediaPipeHelper.dispose();
    // Cleanup subscriptions
    _stateSubscription.cancel();
    _progressSubscription.cancel();
    super.dispose();
  }

  /// Setup initialization state streams
  void _setupInitializationStreams() {
    _stateSubscription = _initManager.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAIServiceInitialized = state.isInitialized;
          _aiServiceStatus = _initManager.statusMessage;
        });
      }
    });

    _progressSubscription = _initManager.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          // Update progress from the manager
        });
      }
    });
  }

  Future<void> _initializeAIService() async {
    // Use the InitializationManager for centralized initialization
    final initialized = await _initManager.initializeAllServices(
      initializeFunction: () => MediaPipeHelper.initializeForChat(useGpu: _useGpu),
      serviceName: 'AI Service',
    );

    if (mounted) {
      setState(() {
        _isAIServiceInitialized = initialized;
        _aiServiceStatus = _initManager.statusMessage;
      });
    }
  }

  /// Retry initialization
  Future<void> _retryInitialization() async {
    final initialized = await _initManager.retryInitialization(
      initializeFunction: () => MediaPipeHelper.initializeForChat(useGpu: _useGpu),
      serviceName: 'AI Service',
    );

    if (mounted) {
      setState(() {
        _isAIServiceInitialized = initialized;
        _aiServiceStatus = _initManager.statusMessage;
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty ||
        !_isAIServiceInitialized ||
        _initManager.isInitializing) {
      return;
    }

    final userMessage = _messageController.text;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _responseText = '';
    });

    // Clear input immediately
    _messageController.clear();

    // Generate response using MediaPipeHelper
    _generateResponse(userMessage);
  }

  void _generateResponse(String userMessage) async {
    try {
      // Generate response using MediaPipeHelper
      final response = await MediaPipeHelper.generateChatResponse(
        userMessage,
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
              _isLoading = false;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _responseText = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate response: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _generateStreamingResponse(String userMessage) async {
    try {
      // Generate streaming response using MediaPipeHelper
      final chunks = <String>[];
      final response = await MediaPipeHelper.generateChatResponseStream(
        userMessage,
        (chunk) {
          chunks.add(chunk);
          if (mounted) {
            setState(() {
              _responseText = chunks.join();
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
              _isLoading = false;
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

      // Final response update
      if (mounted) {
        setState(() {
          _responseText = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate response: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleGpu() {
    setState(() {
      _useGpu = !_useGpu;
    });

    // Reinitialize with new GPU setting
    _initializeAIService();
  }

  void _showInitializationDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_aiServiceStatus'),
            const SizedBox(height: 8),
            Text('GPU Support: ${_useGpu ? "Enabled" : "Disabled"}'),
            const SizedBox(height: 8),
            Text('Progress: ${_initManager.progress}%'),
            const SizedBox(height: 8),
            Text('Current Step: ${_initManager.currentStep}'),
            if (_initManager.elapsedTime.inSeconds > 0)
              Text('Time Elapsed: ${_initManager.formattedElapsedTime}'),
            // if (_initializationError.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Text(
            //       'Error: ${_initManager.errorMessage}',
            //       style: const TextStyle(color: Colors.red),
            //     ),
            //   ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showServiceInfo() async {
    try {
      final modelInfo = await MediaPipeHelper.getModelInfo();
      final serviceStatus = MediaPipeHelper.getServiceStatus();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Service Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $serviceStatus'),
                const SizedBox(height: 8),
                Text('GPU Support: ${_useGpu ? "Enabled" : "Disabled"}'),
                const SizedBox(height: 8),
                const Text('Model Information:'),
                const SizedBox(height: 4),
                Text(modelInfo),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to get service info: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_initManager.isInitializing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Show initialization details',
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showInitializationDetails,
                  tooltip: 'Initialization Details',
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showServiceInfo,
              tooltip: 'Service Information',
            ),
          IconButton(
            icon: Icon(_useGpu ? Icons.memory : Icons.computer),
            onPressed: _initManager.isInitializing ? null : _toggleGpu,
            tooltip: _useGpu ? 'Disable GPU' : 'Enable GPU',
          ),
        ],
      ),
      body: Column(
        children: [
          // Response field (top part - scrollable)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Response',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isAIServiceInitialized
                              ? Colors.green[100]
                              : (_initManager.isInitializing
                                    ? Colors.blue[100]
                                    : Colors.orange[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAIServiceInitialized
                                ? Colors.green[300]!
                                : (_initManager.isInitializing
                                      ? Colors.blue[300]!
                                      : Colors.orange[300]!),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAIServiceInitialized
                                  ? Icons.check_circle
                                  : (_initManager.isInitializing
                                        ? Icons.hourglass_empty
                                        : Icons.error_outline),
                              color: _isAIServiceInitialized
                                  ? Colors.green[600]
                                  : (_initManager.isInitializing
                                        ? Colors.blue[600]
                                        : Colors.orange[600]),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _aiServiceStatus,
                              style: TextStyle(
                                color: _isAIServiceInitialized
                                    ? Colors.green[700]
                                    : (_initManager.isInitializing
                                          ? Colors.blue[700]
                                          : Colors.orange[700]),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _buildResponseContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error message display
          if (_errorMessage != null || _initManager.initializationFailed)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _initManager.initializationFailed
                          ? 'Initialization Failed: ${_initManager.errorMessage}'
                          : _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        // These are now managed by InitializationManager
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          // Input field (bottom part)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Initialization progress overlay
                if (_initManager.isInitializing)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_initManager.currentStep}...',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _initManager.progress / 100,
                          backgroundColor: Colors.blue[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_initManager.progress}%',
                          style: TextStyle(color: Colors.blue[600]!, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // Main input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _isAIServiceInitialized
                              ? 'Type your message...'
                              : (_initManager.isInitializing
                                    ? 'Initializing...'
                                    : 'AI Service Failed'),
                          hintStyle: TextStyle(
                            color: _isAIServiceInitialized
                                ? Colors.grey[500]
                                : (_initManager.isInitializing
                                      ? Colors.grey[400]
                                      : Colors.grey[400]),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: _isAIServiceInitialized
                                  ? Colors.grey[300]!
                                  : (_initManager.isInitializing
                                        ? Colors.blue[300]!
                                        : Colors.grey[300]!),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: _isAIServiceInitialized
                                  ? Colors.grey[300]!
                                  : (_initManager.isInitializing
                                        ? Colors.blue[300]!
                                        : Colors.grey[300]!),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color: _isAIServiceInitialized
                                  ? Colors.blue[400]!
                                  : (_initManager.isInitializing
                                        ? Colors.blue[400]!
                                        : Colors.grey[400]!),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled:
                            _isAIServiceInitialized && !_isLoading && !_initManager.isInitializing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_initManager.isInitializing)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    else if (_initManager.initializationFailed)
                      FloatingActionButton(
                        onPressed: _retryInitialization,
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        child: const Icon(Icons.refresh),
                      )
                    else
                      FloatingActionButton(
                        onPressed: _isAIServiceInitialized ? _sendMessage : null,
                        backgroundColor: _isAIServiceInitialized ? Colors.blue : Colors.grey[400],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        child: const Icon(Icons.send),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent() {
    if (_initManager.isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing AI Service...'),
          ],
        ),
      );
    }

    if (_isLoading && _responseText.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing your request...'),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (_responseText.isEmpty)
          Center(
            child: Text(
              _initManager.isReady
                  ? 'No response yet. Start a conversation!'
                  : 'AI Service ${_initManager.statusMessage}',
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: SelectableText(_responseText, style: const TextStyle(fontSize: 16, height: 1.6)),
          ),
      ],
    );
  }
}
