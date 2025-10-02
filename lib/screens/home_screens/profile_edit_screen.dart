import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dopa_shorts/Providers/app_user_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _userNameController;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _fullNameController = TextEditingController(text: user?.fullname ?? '');
    _userNameController=TextEditingController(text:user?.username??"");
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;

    if (userState.isLoading || user == null) {
      return const Scaffold(backgroundColor:Colors.black,body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (user.profilePicUrl != null
                            ? NetworkImage(user.profilePicUrl!) as ImageProvider
                            : const AssetImage(
                                'assets/images/default_avatar.png',
                              )),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(              
              controller: _fullNameController,
              cursorColor: Colors.white,              
              decoration: const InputDecoration(
                label: Text("Full Name",style:  TextStyle(color: Colors.grey),),
                ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _userNameController,             
              cursorColor: Colors.white,
              decoration: InputDecoration(
                label: Text(
                  user.username,
                  style: const TextStyle(color: Colors.white),
                ),
                hint: Text(
                  user.username,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              enabled: false,
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                 label: Text(
                 user.email,
                  style: const TextStyle(color: Colors.pink),
                ),
                hint: Text(
                  user.email,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await ref
                    .read(userProvider.notifier)
                    .updateProfile(
                      fullName: _fullNameController.text,
                      username:_userNameController.text,
                      newProfilePic: _pickedImage,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated!")),
                );
                Navigator.pop(context); // go back
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
