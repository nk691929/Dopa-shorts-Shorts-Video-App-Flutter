import 'package:dopa_shorts/models/app_user.dart';
import 'package:dopa_shorts/screens/home_screens/others_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final searchUsersProvider = FutureProvider.family<List<AppUser>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];

  final supabase = Supabase.instance.client;

  final results = await supabase
      .from('profiles')
      .select()
      .or('username.ilike.%$query%,full_name.ilike.%$query%');

  return (results as List<dynamic>)
      .map((e) => AppUser.fromMap(e as Map<String, dynamic>))
      .toList();
});

class SearchUsersScreen extends ConsumerStatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  const SearchUsersScreen({super.key, required this.routeObserver});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Add this
  String query = "";

  @override
  void initState() {
    super.initState();
    // Automatically focus the TextField when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // Don't forget to dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchUsersProvider(query));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode, // Assign focus node
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.pink,
          decoration: InputDecoration(
            hintText: "Search users...",
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _controller.clear();
                setState(() {
                  query = "";
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              query = value.trim();
            });
          },
        ),
      ),
      body: searchResult.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No users found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePicUrl != null
                      ? NetworkImage(user.profilePicUrl!)
                      : null,
                  backgroundColor: Colors.grey,
                  child: user.profilePicUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user.fullname,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (Supabase.instance.client.auth.currentUser!.id !=
                      user.id) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OthersProfileScreen(
                          userId: user.id,
                          routeObserver: widget.routeObserver,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/profile');
                  }
                },
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.pink)),
        error: (err, _) => Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
