
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/agent_chat_sheet.dart';

class AgentFloatingButton extends StatelessWidget {
  const AgentFloatingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AgentChatSheet(),
        );
      },
      backgroundColor: Colors.indigo,
      heroTag: 'agent_fab',
      child: const Icon(Icons.auto_awesome),
      tooltip: 'Ask GenSpark Assistant',
    );
  }
}
