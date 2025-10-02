import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final picker = ImagePicker();
  File? _videoFile;
  VideoPlayerController? _videoController;
  final captionController = TextEditingController();
  bool _isUploading = false;
  double _progress = 0.0;
  bool _showControls = true;

  Future<void> _pickVideo() async {
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 15),
    );
    if (pickedFile != null) _setVideoFile(File(pickedFile.path));
  }

  Future<void> _recordVideo() async {
    final pickedFile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 15),
    );
    if (pickedFile != null) _setVideoFile(File(pickedFile.path));
  }

  void _setVideoFile(File file) {
    setState(() {
      _videoFile = file;
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    });
  }


Future<void> _uploadVideoWithDuo() async {
  if (_videoFile == null) return;
  setState(() => _isUploading = true);

  final service = FlutterBackgroundService();
  if (!(await service.isRunning())) {
    await service.startService();
  }

  // Send full upload job to background service
  service.invoke("upload_video", {
    "video_path": _videoFile!.path,
    "caption": captionController.text,
  });

  // Listen for progress updates
  service.on("upload_progress").listen((event) {
    if (event != null) {
      setState(() => _progress = event["progress"]);
    }
  });

  // Listen for completion
  service.on("upload_done").listen((event) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video uploaded successfully!")),
      );
      captionController.clear();
      setState(() {
        _videoFile = null;
        _videoController?.dispose();
        _videoController = null;
        _progress = 0;
        _isUploading = false;
      });
    }
  });

  // Listen for error
  service.on("upload_error").listen((event) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${event?["error"]}")),
      );
      print(event?["error"]);
      setState(() => _isUploading = false);
    }
  });
}




  // Future<void> _uploadVideoWithDuo() async {
  //   if (_videoFile == null) return;
  //   setState(() => _isUploading = true);

  //   try {
  //     final supabase = Supabase.instance.client;
  //     final user = supabase.auth.currentUser;
  //     if (user == null) throw Exception("User not logged in");

  //     final fileName =
  //         "${user.id}/${DateTime.now().millisecondsSinceEpoch}.mp4";
  //     final dio = Dio();
  //     await _videoFile!.readAsBytes();

  //     final formData = FormData.fromMap({
  //       'file': await MultipartFile.fromFile(
  //         _videoFile!.path,
  //         filename: fileName,
  //       ),
  //     });

  //     // Supabase storage endpoint
  //     final storageUrl = "$SUPABASE_URL/storage/v1/object/videos/$fileName";

  //     await dio.post(
  //       storageUrl,
  //       data: formData,
  //       options: Options(
  //         headers: {
  //           'Authorization':
  //               'Bearer ${supabase.auth.currentSession!.accessToken}',
  //         },
  //       ),
  //       onSendProgress: (sent, total) {
  //         setState(() {
  //           _progress = sent / total; // Now tracks actual upload
  //         });
  //       },
  //     );

  //     // Insert video record in database
  //     final response = await supabase
  //         .from('videos')
  //         .insert({
  //           'user_id': user.id,
  //           'video_path': fileName,
  //           'caption': captionController.text,
  //           'created_at': DateTime.now().toIso8601String(),
  //         })
  //         .select()
  //         .single();

  //     final videoId = response['id'] as String;

  //     // Create thumbnail
  //     final tempDir = await getTemporaryDirectory();
  //     final thumbnailPath = await VideoThumbnail.thumbnailFile(
  //       video: _videoFile!.path,
  //       thumbnailPath: tempDir.path,
  //       imageFormat: ImageFormat.JPEG,
  //       maxWidth: 512,
  //       quality: 75,
  //     );

  //     if (thumbnailPath != null) {
  //       final thumbnailFile = File(thumbnailPath);
  //       final thumbnailName = "${user.id}/${videoId}_thumb.jpg";

  //       await supabase.storage
  //           .from('thumbnails')
  //           .upload(thumbnailName, thumbnailFile);

  //       final thumbnailUrl = supabase.storage
  //           .from('thumbnails')
  //           .getPublicUrl(thumbnailName);

  //       await supabase
  //           .from('videos')
  //           .update({
  //             'thumbnail_url': thumbnailUrl,
  //             'thumbnail_path': thumbnailName,
  //           })
  //           .eq('id', videoId);
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Video uploaded successfully!")),
  //       );
  //       captionController.clear();
  //       setState(() {
  //         _videoFile = null;
  //         _videoController?.dispose();
  //         _videoController = null;
  //         _progress = 0;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
  //     }
  //   } finally {
  //     setState(() => _isUploading = false);
  //   }
  // }

  @override
  void dispose() {
    _videoController?.dispose();
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video preview (fixed aspect ratio)
          _videoFile != null &&
                  _videoController != null &&
                  _videoController!.value.isInitialized
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain, // keep original aspect ratio
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey.shade900,
                  width: screenWidth,
                  height: screenHeight,
                  child: const Center(
                    child: Text(
                      "No video selected",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),

          // Overlay controls
          if (_showControls)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Caption input
                  if (_videoFile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Add a caption...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Play/Pause button
                  if (_videoFile != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.black45,
                        child: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),

                  // Bottom buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Record button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _recordVideo,
                            icon: const Icon(
                              Icons.videocam,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Record",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Gallery button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _pickVideo,
                            icon: const Icon(
                              Icons.video_library,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Gallery",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Upload button or progress
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _isUploading
                              ? SizedBox(
                                  height: 48,
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    color: Colors.pink,
                                    backgroundColor: Colors.white24,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _uploadVideoWithDuo,
                                  icon: const Icon(
                                    Icons.cloud_upload,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Upload",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
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
}
