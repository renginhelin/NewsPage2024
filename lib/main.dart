import 'package:flutter/material.dart';
import 'package:news_app/pages/sign_in_page.dart';
import 'package:news_app/pages/sign_up_page.dart';
import 'package:news_app/widgets/news_list.dart';
import 'package:news_app/widgets/news_search_delegate.dart';
import 'package:news_app/services/dio_client.dart';

void main() => runApp(const NewsApp());

class NewsApp extends StatefulWidget {
  const NewsApp({super.key});

  @override
  _NewsAppState createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  bool isSignedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Lato',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 36.0,
              fontWeight: FontWeight.bold,
              color: Colors.black),
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black87),
        ),
      ),
      home: HomePage(isSignedIn: isSignedIn),
      routes: {
        '/signIn': (context) => const SignInPage(),
        '/signUp': (context) => const SignUpPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isSignedIn;

  const HomePage({super.key, required this.isSignedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News Central',
          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: isSignedIn ? _signedInActions(context) : _signedOutActions(context),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: const NewsList(),
      bottomNavigationBar: const Footer(),
    );
  }

  // Actions for signed-in users
  List<Widget> _signedInActions(BuildContext context) {
    return [
      // Search button
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          showSearch(context: context, delegate: NewsSearchDelegate());
        },
      ),
      // Bookmarked button
      IconButton(
        icon: const Icon(Icons.bookmark),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookmarkedNewsPage()),
          );
        },
      ),
      // Log Out button
      TextButton(
        onPressed: () async{
          // Set user as logged out
          await DioClient.dio.post('/logout');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(isSignedIn: false)),
          );
        },
        child: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ];
  }

  // Actions for non-signed-in users
  List<Widget> _signedOutActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          showSearch(context: context, delegate: NewsSearchDelegate());
        },
      ),
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/signIn');
        },
        child: const Text(
          'Sign In',
          style: TextStyle(color: Colors.white),
        ),
      ),
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/signUp');
        },
        child: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ];
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '© 2024 News Central. All rights reserved.',
            style: TextStyle(color: Colors.white, fontSize: 14.0),
          ),
          SizedBox(height: 5.0),
          Text(
            'Privacy Policy | Terms of Use',
            style: TextStyle(color: Colors.white, fontSize: 14.0),
          ),
        ],
      ),
    );
  }
}
