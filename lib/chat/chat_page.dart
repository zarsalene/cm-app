import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// One conversation. Reads [ChatCubit] from the tree.
class ChatPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.select<ChatCubit, Chat?>((c) => c.state.chat);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          chat == null
              ? Strings.chatTitle
              : Strings.customerLabel(chat.customerName, chat.senderId),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (chat != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: ChannelChip(chat.platform),
            ),
        ],
      ),
      body: SafeArea(
        child: chat == null ? const _Loading() : _Conversation(chat: chat),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final error = context.select<ChatCubit, String?>((c) => c.state.error);
    if (error == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(liveRegion: true, child: Text(error)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.read<ChatCubit>().load(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, kMinInteractiveDimension),
            ),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}

class _Conversation extends StatefulWidget {
  const new({required this.chat});

  final Chat chat;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  // Owned here: the give-back dialog needs to know if text is unsent.
  late final _reply = TextEditingController(
    text: context.read<ChatCubit>().state.draft,
  );

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final theme = Theme.of(context);
    final error = context.select<ChatCubit, String?>((c) => c.state.error);
    return Column(
      children: [
        ConstrainedBox(
          // Long reason at large text scale: banner scrolls, no overflow.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.2,
          ),
          child: SingleChildScrollView(
            child: Semantics(
              container: true,
              child: ColoredBox(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${Strings.reasonPrefix}${chat.reason}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _MessageList(messages: chat.messages)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        if (chat.mode == ChatMode.human) ...[
          _Composer(controller: _reply),
          _GiveBackButton(reply: _reply),
        ] else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              Strings.botAnswersAgain,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }
}

class _MessageList extends StatefulWidget {
  const new({required this.messages});

  final List<ChatMessage> messages;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToNewest();
  }

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) _scrollToNewest();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    return RefreshIndicator(
      onRefresh: () => context.read<ChatCubit>().load(),
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: messages.length,
        itemBuilder: (context, i) => _Bubble(message: messages[i]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = message.role != 'customer';
    final background = mine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = mine
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final at = message.at?.toLocal();
    final time = at == null
        ? null
        : '${at.hour.toString().padLeft(2, '0')}:'
              '${at.minute.toString().padLeft(2, '0')}';
    final who = mine ? Strings.bot : Strings.customer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        container: true,
        label: [who, ?time].join(', '),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        message.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const new({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final sending = context.select<ChatCubit, bool>((c) => c.state.sending);
    return BlocListener<ChatCubit, ChatState>(
      // A send succeeded: the cubit cleared the draft, so clear the field.
      listenWhen: (previous, current) =>
          previous.draft.isNotEmpty && current.draft.isEmpty,
      listener: (context, _) => controller.clear(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: sending,
                minLines: 1,
                maxLines: 3,
                maxLength: 2000,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: Strings.replyHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => IconButton.filled(
                tooltip: Strings.send,
                constraints: const BoxConstraints(
                  minWidth: kMinInteractiveDimension,
                  minHeight: kMinInteractiveDimension,
                ),
                onPressed: sending || value.text.trim().isEmpty
                    ? null
                    : () => context.read<ChatCubit>().sendReply(value.text),
                icon: sending
                    ? const SizedBox.square(
                        dimension: AppSpacing.md,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiveBackButton extends StatelessWidget {
  const new({required this.reply});

  final TextEditingController reply;

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.giveBackTitle),
        content: Text(
          reply.text.trim().isEmpty
              ? Strings.giveBackBody
              : '${Strings.giveBackBody} ${Strings.draftLost}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Strings.confirm),
          ),
        ],
      ),
    );
    if ((ok ?? false) && !cubit.isClosed) await cubit.giveBack();
  }

  @override
  Widget build(BuildContext context) {
    final sending = context.select<ChatCubit, bool>((c) => c.state.sending);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: sending ? null : () => _confirm(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(kMinInteractiveDimension),
          ),
          child: const Text(Strings.giveBack),
        ),
      ),
    );
  }
}
