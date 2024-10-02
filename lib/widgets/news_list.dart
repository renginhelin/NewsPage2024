import 'dart:async';
import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/services/dio_client.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NewsList extends StatefulWidget {
  const NewsList({super.key});

  @override
  _NewsListState createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isAtTop = true;
  final List<String> _categories = [
    'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'
  ];

  // Cache for news articles by category
  final Map<String, List<NewsArticle>> _cachedArticles = {};
  final Map<String, bool> _loadingStates = {}; // To track if a category is loading

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _scrollController = ScrollController();

    // Initialize loading states to true (meaning they need to load initially)
    for (var category in _categories) {
      _loadingStates[category] = true;
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 50) {
        setState(() {
          _isAtTop = true;
        });
      } else {
        setState(() {
          _isAtTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndCacheArticles(String category) async {
    if (_loadingStates[category] == true) {
      // Fetch the articles if they are not cached
      final articles = await _newsService.fetchNewsByCategory(category);

      final filteredArticles = articles.where((article) =>
      !(article.title.contains("[Removed]") || article.description.contains("[Removed]"))
      ).toList();

      setState(() {
        _cachedArticles[category] = filteredArticles;
        _loadingStates[category] = false; // Mark the category as loaded
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: _isAtTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const TopNewsCarousel(),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.deepPurple,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                tabs: _categories
                    .map((category) => Tab(text: category.capitalize()))
                    .toList(),
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return FutureBuilder<void>(
            future: _fetchAndCacheArticles(category),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _loadingStates[category] == true) {
                // Show loading spinner only the first time loading
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                // Load cached articles
                final articles = _cachedArticles[category] ?? [];

                if (articles.isEmpty) {
                  return const Center(child: Text('No articles available'));
                }

                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 5,
                      margin: const EdgeInsets.all(12.0),
                      child: InkWell(
                        onTap: () => _launchURL(article.url),  // When user taps the article, open the URL
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12.0),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: article.imageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    article.description,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Other content can go here, e.g. author, date
                                      IconButton(
                                        icon: Icon(Icons.bookmark_border),  // Bookmark button icon
                                        onPressed: () {
                                          // Call the function to add to bookmarks
                                          _addBookmark(article);  // Define this function to save the article
                                        },
                                        tooltip: 'Bookmark this article',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _addBookmark(NewsArticle article) async {
    final dio = DioClient.dio; // Use the shared Dio instance
    final url = '/add_bookmark'; // Relative URL since baseUrl is set in Dio options

    try {
      final response = await dio.post(
        url,
        data: {
          'title': article.title,
          'description': article.description,
          'url': article.url,
          'imageUrl': article.imageUrl,
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark added!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add bookmark: ${response.data["error"]}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class BookmarkedNewsPage extends StatefulWidget {
  const BookmarkedNewsPage({Key? key}) : super(key: key);

  @override
  _BookmarkedNewsPageState createState() => _BookmarkedNewsPageState();
}

class _BookmarkedNewsPageState extends State<BookmarkedNewsPage> {
  List<NewsArticle> _bookmarkedArticles = [];

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    final dio = DioClient.dio; // Use the shared Dio instance
    final url = '/bookmarks'; // Use relative URL since baseUrl is already set in DioClient

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> bookmarks = response.data;
        setState(() {
          _bookmarkedArticles = bookmarks.map((bookmark) => NewsArticle.fromJson(bookmark)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookmarks: ${response.data["error"]}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeBookmark(NewsArticle article) async {
    final dio = DioClient.dio;  // Use the shared Dio instance
    final url = '/remove_bookmark';  // The remove bookmark endpoint

    try {
      final response = await dio.post(
        url,
        data: {
          'url': article.url,  // Assuming the article's URL is the unique identifier
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookmarkedArticles.remove(article);  // Remove article from the list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark removed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove bookmark: ${response.data["error"]}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked News'),
      ),
      body: ListView.builder(
        itemCount: _bookmarkedArticles.length,
        itemBuilder: (context, index) {
          final article = _bookmarkedArticles[index];
          return Card(
            child: ListTile(
              title: Text(article.title),
              subtitle: Text(article.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete),  // Icon for remove button
                onPressed: () {
                  _removeBookmark(article);  // Call the function to remove the bookmark
                },
              ),
              onTap: () => _launchURL(article.url),
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class TopNewsCarousel extends StatefulWidget {
  const TopNewsCarousel({super.key});

  @override
  _TopNewsCarouselState createState() => _TopNewsCarouselState();
}

class _TopNewsCarouselState extends State<TopNewsCarousel> {
  final NewsService _newsService = NewsService();
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;
  final List<String> _categories = [
    'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'
  ];

  // List to store the first article of each category
  List<NewsArticle?> _topArticles = [];

  @override
  void initState() {
    super.initState();
    _fetchTopArticles();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Fetch top articles from each category and filter out "[Removed]" articles
  void _fetchTopArticles() async {
    for (String category in _categories) {
      final articles = await _newsService.fetchNewsByCategory(category);

      // Filter out articles with "[Removed]" in title or description
      final filteredArticles = articles.where((article) =>
      !(article.title.contains("[Removed]") || article.description.contains("[Removed]"))
      ).toList();

      setState(() {
        _topArticles.add(filteredArticles.isNotEmpty ? filteredArticles.first : null);
      });
    }
  }

  // Automatically scroll pages every 5 seconds
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _categories.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _topArticles.isNotEmpty
        ? SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _categories.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final article = _topArticles[index];
          return article != null
              ? InkWell(
            onTap: () => _launchURL(article.url),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      article.title,
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
              : const Center(child: Text('No article available'));
        },
      ),
    )
        : const Center(child: CircularProgressIndicator());
  }

  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

// Extension to add capitalize method to the String class
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
