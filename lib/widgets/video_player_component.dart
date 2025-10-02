import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerComponent extends StatefulWidget {
  final String videoUrl;
  final RouteObserver<ModalRoute<void>> routeObserver;
  final String videoId; // 👈 add videoId so we know which video to update
  final Future<void> Function(String videoId)? onAddView; // 👈 callback to update views

  const VideoPlayerComponent({
    super.key,
    required this.videoUrl,
    required this.routeObserver,
    required this.videoId,
    this.onAddView,
  });

  @override
  State<VideoPlayerComponent> createState() => VideoPlayerComponentState();
}

class VideoPlayerComponentState extends State<VideoPlayerComponent>
    with RouteAware {
  late VideoPlayerController _videoPlayerController;
  bool _viewAdded = false; // 👈 prevent duplicate view counts

  void pauseVideo() => _videoPlayerController.pause();
  void playVideo() => _videoPlayerController.play();

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.play();
            _videoPlayerController.setLooping(true);
          });

    // 👇 Listen to playback progress
    _videoPlayerController.addListener(_checkViewTrigger);
  }

  void _checkViewTrigger() {
    if (_videoPlayerController.value.isInitialized &&
        _videoPlayerController.value.position.inSeconds >= 3 && // 👈 3-second rule
        !_viewAdded) {
      _viewAdded = true; // mark as counted
      widget.onAddView?.call(widget.videoId); // trigger backend update
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    _videoPlayerController.removeListener(_checkViewTrigger); // 👈 clean up
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() => pauseVideo();
  @override
  void didPopNext() => playVideo();

  @override
  Widget build(BuildContext context) {
    return _videoPlayerController.value.isInitialized
        ? GestureDetector(
            onTap: () {
              _videoPlayerController.value.isPlaying
                  ? _videoPlayerController.pause()
                  : _videoPlayerController.play();
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoPlayerController.value.size.width,
                  height: _videoPlayerController.value.size.height,
                  child: VideoPlayer(_videoPlayerController),
                ),
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
