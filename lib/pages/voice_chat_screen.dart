import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).dialogBackgroundColor,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            // _buildStatusBar(),
            Expanded(
              child: _buildMessageList(),
            ),
            SafeArea(
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor,
          child: Row(
            children: [
              const Text(
                'Voice Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // 录音控制按钮
              IconButton(
                icon: Icon(
                  provider.isRecording ? Icons.mic_off : Icons.mic,
                  color: provider.isRecording ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  if (provider.isRecording) {
                    provider.stopRecording();
                  } else {
                    provider.resumeRecording();
                  }
                },
              ),
              _buildAudioControls(),
            ],
          ),
        );
      },
    );
  }

// 同时可以简化状态栏的显示

  Widget _buildAudioControls() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                provider.volume > 0 ? Icons.volume_up : Icons.volume_off,
                color: provider.isAIResponding ? Colors.green : Colors.white,
              ),
              onPressed: provider.toggleMute,
            ),
            if (provider.volume > 0)
              SizedBox(
                width: 100,
                child: Slider(
                  value: provider.volume,
                  onChanged: provider.setVolume,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withAlpha(76),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[provider.messages.length - 1 - index];
            return MessageBubble(message: message);
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      constraints: const BoxConstraints(
        minHeight: 64,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 100,
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    context.read<ChatProvider>().sendTextMessage(text);
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: Material(
              color: Theme.of(context).primaryColor,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    context.read<ChatProvider>().sendTextMessage(_textController.text);
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
