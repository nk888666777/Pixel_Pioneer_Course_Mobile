import 'package:course_template/screens/my_courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'package:course_template/models/category.dart';
import 'package:course_template/models/course.dart';
import 'package:course_template/screens/category_list_screen.dart';
import 'package:course_template/screens/chat_screen.dart';
import 'package:course_template/screens/course_details_screen.dart';
import 'package:course_template/screens/course_selection_screen.dart';
import 'package:course_template/screens/profile_screen.dart';
import 'package:course_template/widgets/course_chip.dart';
import 'package:course_template/widgets/custom_button.dart';
import 'package:course_template/widgets/custom_text_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Category> _categories = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _userFullname;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final categoriesResponse =
        await http.get(Uri.parse('http://10.0.2.2:8080/api/category'));
    final coursesResponse =
        await http.get(Uri.parse('http://10.0.2.2:8080/api/course'));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userFullname = prefs.getString("userFullname") ?? 'User';
    _userId = prefs.getInt("userId");

    if (categoriesResponse.statusCode == 200 &&
        coursesResponse.statusCode == 200) {
      final List<dynamic> categoriesData = jsonDecode(categoriesResponse.body);
      final List<dynamic> coursesData = jsonDecode(coursesResponse.body);

      final List<Category> fetchedCategories =
          categoriesData.map((json) => Category.fromJson(json)).toList();
      final List<Course> fetchedCourses =
          coursesData.map((json) => Course.fromJson(json)).toList();

      setState(() {
        _categories = fetchedCategories;
        _courses = fetchedCourses;
        _isLoading = false;
      });
    } else {
      setState(() {
        _categories = [];
        _courses = [];
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/profile.jpg'),
                radius: 20,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userFullname ?? 'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Find your course and enjoy new arrivals✨',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.notifications, size: 28),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  List<Widget> get _widgetOptions => [
        HomePage(
          courses: _courses,
          categories: _categories,
        ),
        const CategoryListScreen(),
        const ChatScreen(),
        const ProfileScreen(),
      ];
}

class HomePage extends StatelessWidget {
  final List<Course> courses;
  final List<Category> categories;

  const HomePage({
    super.key,
    required this.courses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          CustomTextField(
            hintText: 'Search Courses Here...',
            controller: TextEditingController(),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Courses You May Like', onTap: () {
            // Handle "See more" action
          }),
          _buildTodaySessions(context),
          const SizedBox(height: 16),
          _buildSectionHeader('Categories', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoryListScreen()),
            );
          }),
          _buildCategories(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'See more',
            style: TextStyle(color: Colors.purple),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required String title,
    required String author,
    required String image,
  }) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CourseDetailsScreen(courseName: title)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenSize.height * 0.12,
              width: screenSize.width *
                  0.3, // Constrain the width and height to 5% of screen width
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Image not available'));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Instructor: $author",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySessions(BuildContext context) {
    if (courses.isEmpty) {
      return const Text('No courses available now.');
    }

    final random = Random();
    final shuffledCourses = courses.toList()..shuffle(random);
    final selectedCourses =
        shuffledCourses.take(2 + random.nextInt(2)).toList();

    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: selectedCourses.map((course) {
          return _buildCourseCard(
            context,
            title: course.title,
            author: course.instructorName,
            image: course.imageUrl,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories available now.');
    }

    final random = Random();
    final shuffledCategories = categories.toList()..shuffle(random);
    final selectedCategories =
        shuffledCategories.take((4 + random.nextInt(3))).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: selectedCategories.map((category) {
        return CourseChip(
          label: category.name,
          backgroundColor: Colors.purple[100],
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => CourseListScreen(category: category)),
            );
          },
        );
      }).toList(),
    );
  }
}
