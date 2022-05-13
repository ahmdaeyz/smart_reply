import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:smart_reply/smart_reply.dart' as sr;

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
    required this.room,
  }) : super(key: key);

  final types.Room room;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> suggestions = [];
  types.Room? room;
  StreamSubscription? sub;

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  void _handleSendPressed(types.PartialText message) {
    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Chat'),
      ),
      body: StreamBuilder<types.Room>(
        initialData: widget.room,
        stream: FirebaseChatCore.instance.room(widget.room.id),
        builder: (context, snapshot) {
          room = snapshot.data;
          if (sub == null) {
            sub =
                FirebaseChatCore.instance.messages(room!).listen((data) async {
              final currentUserId =
                  FirebaseAuth.instance.currentUser?.uid ?? '';
              final messages = data;
              final numToTake = messages.length.clamp(0, 20);
              final predictionSample =
                  messages.take(numToTake).toList().reversed;
              suggestions = await const sr.SmartReply().suggestReplies(
                  predictionSample
                      .map((e) => sr.TextMessage(
                          text: (e as types.TextMessage).text,
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              e.createdAt ?? 0),
                          userId: e.author.id,
                          isLocalUser: e.author.id == currentUserId))
                      .toList());
              debugPrint("SUGGESTIONS: " + suggestions.toString());
              setState(() {});
            });
          }
          return StreamBuilder<List<types.Message>>(
            initialData: const [],
            stream: FirebaseChatCore.instance.messages(snapshot.data!),
            builder: (context, snapshot) {
              return Chat(
                theme: DefaultChatTheme(
                    primaryColor: Theme.of(context).primaryColor),
                messages: snapshot.data ?? [],
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                user: types.User(
                  id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
                ),
                customBottomWidget: ChatInputWithSuggestions(
                    suggestions: suggestions,
                    onSendPressed: _handleSendPressed),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatInputWithSuggestions extends StatefulWidget {
  final List<String> suggestions;
  final Function(types.PartialText) onSendPressed;

  const ChatInputWithSuggestions(
      {Key? key, required this.suggestions, required this.onSendPressed})
      : super(key: key);

  @override
  State<ChatInputWithSuggestions> createState() =>
      _ChatInputWithSuggestionsState();
}

class _ChatInputWithSuggestionsState extends State<ChatInputWithSuggestions> {
  final messageTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Material(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).primaryColor,
        child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (widget.suggestions.isNotEmpty)
                  Wrap(
                      children: List.generate(
                    widget.suggestions.length * 2 - 1,
                    (index) => index % 2 == 0
                        ? ActionChip(
                            label: Text(widget.suggestions[index ~/ 2]),
                            onPressed: () {
                              messageTextEditingController.text =
                                  widget.suggestions[index ~/ 2];
                            })
                        : SizedBox(width: 8.0),
                  )),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageTextEditingController,
                        keyboardType: TextInputType.multiline,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            ?.copyWith(color: Colors.white),
                        maxLines: 5,
                        minLines: 1,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    Visibility(
                      child: SendButton(
                        onPressed: () {
                          widget.onSendPressed(types.PartialText(
                              text: messageTextEditingController.text));
                          messageTextEditingController.clear();
                        },
                      ),
                    ),
                  ],
                )
              ],
            )));
  }
}
