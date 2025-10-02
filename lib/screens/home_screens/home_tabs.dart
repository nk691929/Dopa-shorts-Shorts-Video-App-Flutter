// import 'package:dopa_shorts/screens/home_screens/home_screen.dart';
// import 'package:dopa_shorts/screens/home_screens/profile_screen.dart';
// import 'package:dopa_shorts/screens/home_screens/ulpoad_video.dart';
// import 'package:flutter/material.dart';
// import 'package:google_nav_bar/google_nav_bar.dart';

// class HomeTabs extends StatefulWidget {
//   final RouteObserver<ModalRoute<void>> routeObserver;
//   const HomeTabs({super.key,required this.routeObserver});

//   @override
//   State<HomeTabs> createState() => _HomeTabsState();
// }

// class _HomeTabsState extends State<HomeTabs> {
//   int _slectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> pages = [
//     HomeScreen(routeObserver: widget.routeObserver,),
//     UploadVideoScreen(),
//     UploadProfileScreen(routeObserver: widget.routeObserver,),
//   ];
//     return Stack(
//       children: [
//         Positioned(
//           top:0,
//           bottom: 55,
//           right: 0,
//           left: 0,
//           child: pages[_slectedIndex]),

//         // Absolute positioned bottom nav
//         Positioned(
//           left: 15,
//           right: 15,
//           bottom: 10,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(25),
//               color: Colors.black,
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//               child: GNav(
//                 padding: const EdgeInsets.all(6),
//                 backgroundColor: Colors.black,
//                 color: Colors.pink,
//                 selectedIndex: _slectedIndex,
//                 onTabChange: (index) {
//                   setState(() {
//                     _slectedIndex = index;
//                   });
//                 },
//                 gap: 8,
//                 tabBackgroundColor: Colors.grey,
//                 activeColor: Colors.pink,
//                 iconSize: 30,
//                 tabs: const [
//                   GButton(icon: Icons.home, text: "Home"),
//                   GButton(icon: Icons.add_circle_outline, text: "Upload Video"),
//                   GButton(icon: Icons.person, text: "Profile"),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:dopa_shorts/screens/home_screens/home_screen.dart';
import 'package:dopa_shorts/screens/home_screens/profile_screen.dart';
import 'package:dopa_shorts/screens/home_screens/ulpoad_video.dart';
import 'package:flutter/material.dart';

class HomeTabs extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  const HomeTabs({super.key, required this.routeObserver});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(routeObserver: widget.routeObserver),
      UploadVideoScreen(),
      UploadProfileScreen(routeObserver: widget.routeObserver),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add, size: 35),
            label: "Upload Video",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 35),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
