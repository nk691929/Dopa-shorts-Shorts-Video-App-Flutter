import 'dart:ui';

import 'package:dopa_shorts/Providers/comment_provider.dart';
import 'package:dopa_shorts/models/app_user.dart';
import 'package:dopa_shorts/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String videoId;
  final String userId;
  final String vidOwnerId;

  const CommentSection({
    super.key,
    required this.videoId,
    required this.userId,
    required this.vidOwnerId,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(commentProvider.notifier).loadComments(widget.videoId);
    });
  }

  Future<AppUser?> fetchUser(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // drag handle
            Container(
              height: 40,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const Text(
              "Comments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(),

            // comment list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: state.isLoading
                    ? 5 // show 5 skeleton items while loading
                    : state.comments.length,
                itemBuilder: (context, index) {
                  if (state.isLoading) {
                    // Skeleton placeholder
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        radius: 20,
                      ),
                      title: Container(
                        height: 10,
                        color: Colors.grey[100],
                        margin: const EdgeInsets.only(bottom: 5),
                      ),
                      subtitle: Container(height: 10, color: Colors.grey[100]),
                    );
                  }

                  final comment = state.comments[index];

                  return FutureBuilder<AppUser?>(
                    future: fetchUser(comment.userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        // Loading placeholder for this particular comment
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            radius: 20,
                          ),
                          title: Container(
                            height: 10,
                            color: Colors.grey[100],
                            margin: const EdgeInsets.only(bottom: 5),
                          ),
                          subtitle: Container(
                            height: 10,
                            color: Colors.grey[100],
                          ),
                        );
                      }

                      final user = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // === Parent Comment ===
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePicUrl != null
                                  ? NetworkImage(user.profilePicUrl!)
                                  : null,
                              child: user.profilePicUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              user.username.isNotEmpty
                                  ? user.username
                                  : "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            subtitle: Text(
                              comment.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade100,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(comment.createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.reply,
                                    color: Colors.pink,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showReplyDialog(context, comment.id),
                                ),
                                if (comment.userId == widget.userId)
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        await ref
                                            .read(commentProvider.notifier)
                                            .deleteComment(comment.id);
                                      } else if (value == 'edit') {
                                        _showEditDialog(context, comment);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // === Replies (nested) ===
                          FutureBuilder<List<Comment>>(
                            future: ref
                                .read(commentProvider.notifier)
                                .loadReplies(comment.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final replies = snapshot.data!;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 50,
                                  bottom: 10,
                                ),
                                child: Column(
                                  children: replies.map((reply) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.subdirectory_arrow_right,
                                        color: Colors.pink,
                                      ),
                                      title: Text(
                                        reply.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _formatTime(reply.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.reply,
                                              color: Colors.pink,
                                              size: 18,
                                            ),
                                            onPressed: () => _showReplyDialog(
                                              context,
                                              reply.id,
                                            ),
                                          ),
                                          if (reply.userId == widget.userId)
                                            PopupMenuButton<String>( 
                                              surfaceTintColor: Colors.grey.shade900,                                             
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                              ),
                                              onSelected: (value) async {
                                                if (value == 'delete') {
                                                  await ref
                                                      .read(
                                                        commentProvider
                                                            .notifier,
                                                      )
                                                      .deleteComment(reply.id);
                                                } else if (value == 'edit') {
                                                  _showEditDialog(
                                                    context,
                                                    reply,
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text("Edit",style: TextStyle(color: Colors.white),),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text("Delete",style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // input field
            SafeArea(
              child: // input field
              Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        cursorColor: Colors.pink,
                        decoration: InputDecoration(
                          hint: Text(
                            "Add a comment...",
                            style: TextStyle(color: Colors.grey.shade200),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ), // default border color
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.pink,
                              width: 2,
                            ), // color when typing
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.pink),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          ref
                              .read(commentProvider.notifier)
                              .addComment(widget.videoId, widget.userId, text,vidOwnerId:  widget.vidOwnerId);
                          _controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _showEditDialog(BuildContext context, Comment comment) {
    final editController = TextEditingController(text: comment.text);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // 👈 dim + transparent
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // 👈 blur strength
        child: AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            "Edit Comment",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: editController,
            maxLines: null,
            decoration: const InputDecoration(
              hint: Text(
                "Edit your comment",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  await ref
                      .read(commentProvider.notifier)
                      .updateComment(comment.id, newText);
                }
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String parentId) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.3), // 👈 dim + transparent
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // 👈 blur strength
        child: AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            "Write a reply",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              hint: Text(
                "Your reply...",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, // background
                foregroundColor: Colors.white, // text
              ),
              onPressed: () async {
                final replyText = replyController.text.trim();
                if (replyText.isNotEmpty) {
                  await ref
                      .read(commentProvider.notifier)
                      .addComment(
                        widget.videoId,
                        widget.userId,
                        replyText,
                        parentId: parentId,
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text("Reply"),
            ),
          ],
        ),
      ),
    );
  }
}
