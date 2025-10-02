import 'package:dopa_shorts/Providers/follow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FollowActionButton extends ConsumerWidget {
  final String profileUserId;

  // Flexible size
  final double? width;
  final double? height;

  const FollowActionButton({
    super.key,
    required this.profileUserId,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(followProviderState(profileUserId));

    return followAsync.when(
      data: (followState) {
        final isFollowing = followState.isFollowing;

        final label = isFollowing ? "Unfollow" : "Follow";
        final color = isFollowing ? Colors.grey : Colors.pink;
        final icon = isFollowing ? Icons.check : Icons.add;

        final button = ElevatedButton(
          onPressed: () async {
            await ref
                .read(followProviderState(profileUserId).notifier)
                .toggleFollow();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown, // shrink contents if needed
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Wrap with SizedBox if width/height provided
        if (width != null || height != null) {
          return SizedBox(
            width: width,
            height: height,
            child: button,
          );
        }
        return button;
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, _) => Text("Error: $err"),
    );
  }
}
