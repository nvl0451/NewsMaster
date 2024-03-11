import 'package:flutter/material.dart';
import 'package:news_master/models/article_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: must_be_immutable
class ArticleWebView extends StatefulWidget {
  ArticleModel article;

  ArticleWebView({required this.article});

  //const ArticleWebView({super.key});

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  @override
  Widget build(BuildContext context) {
    var controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.article.url ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title ?? ''),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
