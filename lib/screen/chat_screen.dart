import 'package:flutter/material.dart';
import '../helpers/mediapipe_helper.dart';

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
  bool _isMediaPipeInitialized = false;
  String _mediaPipeStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeMediaPipe();
  }

  Future<void> _initializeMediaPipe() async {
    setState(() {
      _mediaPipeStatus = 'Initializing MediaPipe...';
    });

    try {
      final initialized = await MediaPipeHelper.initialize(useGpu: false);
      if (mounted) {
        setState(() {
          _isMediaPipeInitialized = initialized;
          _mediaPipeStatus = initialized
              ? 'MediaPipe Initialized'
              : 'MediaPipe Failed to Initialize';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMediaPipeInitialized = false;
          _mediaPipeStatus = 'Error: ${e.toString()}';
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_isMediaPipeInitialized) {
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

    // Use streaming response for better UX
    MediaPipeHelper.generateResponseStream(
      userMessage,
      (chunk) {
        setState(() {
          _responseText += chunk;
        });

        // Auto-scroll to bottom when new content is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'MediaPipe Error: $error';
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
    ).catchError((error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate response: $error';
          _isLoading = false;
        });
      }
    });
  }

  void _handleError(String error) {
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    MediaPipeHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaPipe Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isMediaPipeInitialized
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isMediaPipeInitialized
                                ? Colors.green[300]!
                                : Colors.orange[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMediaPipeInitialized
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _isMediaPipeInitialized
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _mediaPipeStatus,
                              style: TextStyle(
                                color: _isMediaPipeInitialized
                                    ? Colors.green[700]
                                    : Colors.orange[700],
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
          if (_errorMessage != null)
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
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isMediaPipeInitialized
                          ? 'Type your message...'
                          : 'Initializing MediaPipe...',
                      hintStyle: TextStyle(
                        color: _isMediaPipeInitialized
                            ? Colors.grey[500]
                            : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: _isMediaPipeInitialized
                              ? Colors.grey[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: _isMediaPipeInitialized
                              ? Colors.grey[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: _isMediaPipeInitialized
                              ? Colors.blue[400]!
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isMediaPipeInitialized && !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                _isLoading
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                    : FloatingActionButton(
                        onPressed: _isMediaPipeInitialized
                            ? _sendMessage
                            : null,
                        backgroundColor: _isMediaPipeInitialized
                            ? Colors.blue
                            : Colors.grey[400],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        child: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent() {
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
              'No response yet. Start a conversation!',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
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
            child: SelectableText(
              _responseText,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
      ],
    );
  }
}
