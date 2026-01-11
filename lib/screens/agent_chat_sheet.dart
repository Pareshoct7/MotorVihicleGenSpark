
import 'package:flutter/material.dart';
import 'package:flutter_app/services/agent_service.dart';

class AgentChatSheet extends StatefulWidget {
  const AgentChatSheet({Key? key}) : super(key: key);

  @override
  State<AgentChatSheet> createState() => _AgentChatSheetState();
}

class _AgentChatSheetState extends State<AgentChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AgentMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addSystemMessage("Hello! I'm your offline assistant. How can I help you?");
    // Ensure commands are initialized
    AgentService().init();
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(AgentMessage(text: text, isUser: false));
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = AgentMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate "thinking" delay for realism
    await Future.delayed(const Duration(milliseconds: 600));

    // Process via AgentService
    final response = await AgentService().processQuery(text, context);

    setState(() {
      _isTyping = false;
      _messages.add(response);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'GenSpark Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thinking...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Input Area
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask me to do something...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _handleSubmitted(_controller.text),
                  backgroundColor: Colors.indigo,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AgentMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser)
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 4),
                  child: Icon(Icons.smart_toy, size: 20, color: Colors.indigo),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.indigo : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (msg.actionWidget != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: msg.actionWidget!,
            ),
        ],
      ),
    );
  }
}
