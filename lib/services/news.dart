import 'dart:convert';

import 'package:news_master/models/article_model.dart';
import 'package:http/http.dart' as http;

class News {
  List<ArticleModel> news = [];

  Future<void> getNews() async {
    String url =
        "https://newsapi.org/v2/everything?q=apple&apiKey=d3b89a1aa7c6498e8ab7ba4c726c5cb1";

    var response = await http.get(Uri.parse(url));

    var jsonData = jsonDecode(response.body);

    //print(jsonData);

    if (jsonData['status'] == 'ok') {
      jsonData['articles'].forEach((element) {
        if (element['urlToImage'] != null && element['description'] != null) {
          ArticleModel articleModel = ArticleModel(
              title: element['title'],
              author: element['author'],
              description: element['description'],
              url: element['url'],
              urlToImage: element['urlToImage'],
              content: element['content']);
          news.add(articleModel);
        }
      });
    }
  }
}
