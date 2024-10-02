import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news_app/models/news_model.dart';

class NewsService {
  final String _apiKey = '1ae99958fda54db795575e524d2bd2dc';

  // Fetch news articles by category
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    final Uri url = Uri.parse(
        'https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$_apiKey');
    final http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return (data['articles'] as List)
          .map((articleJson) => NewsArticle.fromJson(articleJson))
          .toList();
    } else if (response.statusCode == 400){
      throw Exception('Bad Request');
    } else if (response.statusCode == 401){
      throw Exception('Unauthorized');
    } else if (response.statusCode == 429){
      throw Exception('Too Many Requests');
    } else if (response.statusCode == 500){
      throw Exception('Server Error');
    } else{
      throw Exception('Failed to Load News');
    }
  }

  // Search news by a query
  Future<List<NewsArticle>> searchNews(String query) async {
    final Uri url = Uri.parse(
        'https://newsapi.org/v2/everything?q=$query&apiKey=$_apiKey');
    final http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return (data['articles'] as List)
          .map((articleJson) => NewsArticle.fromJson(articleJson))
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }
}
