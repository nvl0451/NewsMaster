// ignore_for_file: must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:news_master/models/article_model.dart';
import 'package:news_master/pages/article_view.dart';
import 'package:news_master/pages/favorites_view.dart';
import 'package:news_master/services/news.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Variable init
  List<ArticleModel> articles = [];
  bool _loadingNews = true;
  bool _loadingFavs = true;

  late Future<Database> favoriteArticles;
  List<ArticleModel> favoriteArticlesList = [];
  int favoriteArticlesAmount = 0;

  int activeIndex = 0;

  // Main State Init

  @override
  void initState() {
    getNews();
    getDatabase();
    super.initState();
  }

  // API Access

  getNews() async {
    News newsClass = News();
    await newsClass.getNews();
    articles = newsClass.news;
    setState(() {
      _loadingNews = false;
    });
  }

  // Database functionality for "Add to Favorites" feature

  getDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();

    final favoriteArticlesDB = openDatabase(
      Path.join(await getDatabasesPath(), 'favorite_articles_database.db'),
      onCreate: ((db, version) {
        return db.execute(
          'CREATE TABLE favorites(author STRING, title STRING, description STRING, url STRING PRIMARY KEY, urlToImage STRING, content STRING)',
        );
      }),
      version: 1,
    );

    favoriteArticles = favoriteArticlesDB;

    favoriteArticlesList = await retrieveFavorites();

    print(favoriteArticlesList);

    favoriteArticlesAmount = favoriteArticlesList.length;

    setState(() {
      _loadingFavs = false;
    });
  }

  Future<void> insertArticle(ArticleModel articleModel) async {
    final db = await favoriteArticles;
    await db.insert('favorites', articleModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteArticle(ArticleModel articleModel) async {
    final db = await favoriteArticles;
    await db
        .delete('favorites', where: 'url = ?', whereArgs: [articleModel.url]);
    await getDatabase();
  }

  Future<void> clearDatabase() async {
    final db = await favoriteArticles;
    await db.delete('favorites');
    print('db cleared');
  }

  Future<List<ArticleModel>> retrieveFavorites() async {
    final db = await favoriteArticles;
    final List<Map<String, Object?>> articleMaps = await db.query('favorites');
    return [
      for (final {
            'author': author as String?,
            'title': title as String?,
            'description': description as String?,
            'url': url as String?,
            'urlToImage': urlToImage as String?,
            'content': content as String?
          } in articleMaps)
        ArticleModel(
            author: author,
            title: title,
            description: description,
            url: url,
            urlToImage: urlToImage,
            content: content)
    ];
  }

  // Navigation to Article View with DB reload on return

  Future<void> _navigateToArticleView(ArticleModel articleModel) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ArticleView(article: articleModel)));

    if (!context.mounted) return;

    getDatabase();
  }

  Future<void> _navigateToFavoritesView() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => FavoritesView()));

    if (!context.mounted) return;

    getDatabase();
  }

  // Main Widget Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("News"),
            Text("Master",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ],
        ),
        centerTitle: true,
        elevation: 0.0,
        actions: [
          IconButton(
              icon: Icon(Icons.delete),
              iconSize: 30,
              color: Colors.black,
              onPressed: () {
                clearDatabase();
                getDatabase();
              }),
        ],
      ),
      body: (_loadingNews || _loadingFavs)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (favoriteArticlesAmount == 0)
                      ? SizedBox(
                          height: 0,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Favorite News",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: "Montserrat"),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _navigateToFavoritesView();
                                    },
                                    child: Text(
                                      "View All",
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            CarouselSlider.builder(
                                itemCount: favoriteArticlesAmount,
                                itemBuilder: (context, index, realIndex) {
                                  ArticleModel article =
                                      favoriteArticlesList[index];
                                  return buildImage(article, index);
                                },
                                options: CarouselOptions(
                                    height: 250,
                                    autoPlay: (favoriteArticlesAmount >= 2),
                                    enlargeCenterPage: true,
                                    enlargeStrategy:
                                        CenterPageEnlargeStrategy.height,
                                    enableInfiniteScroll:
                                        (favoriteArticlesAmount >= 2),
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        activeIndex = index;
                                      });
                                    })),
                            SizedBox(height: 15),
                            (favoriteArticlesAmount >= 2)
                                ? Center(child: buildIndicator())
                                : SizedBox(
                                    height: 0,
                                  ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Trending News",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: "Montserrat"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    child: ListView.builder(
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: articles.length,
                        itemBuilder: ((context, index) {
                          return buildBlogTile(articles[index]);
                        })),
                  )
                ],
              ),
            ),
    );
  }

  Widget buildImage(ArticleModel article, int index) => Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: GestureDetector(
          onTap: () {
            print(article.url);
            _navigateToArticleView(article);
          },
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              child: CachedNetworkImage(
                height: 150,
                imageUrl: article.urlToImage ?? '',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Container(
              height: 250,
              padding: EdgeInsets.only(left: 10),
              margin: EdgeInsets.only(top: 150),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
              child: Center(
                child: Text(
                  article.title ?? 'invalid title',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ]),
        ),
      );

  Widget buildIndicator() => AnimatedSmoothIndicator(
        activeIndex: activeIndex,
        count: favoriteArticlesAmount,
        effect: SlideEffect(
            dotWidth: 10, dotHeight: 10, activeDotColor: Colors.blue),
      );

  Widget buildBlogTile(ArticleModel article) {
    return GestureDetector(
      onTap: () {
        print(article.url);
        _navigateToArticleView(article);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: Material(
            elevation: 3.0,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: article.urlToImage ?? '',
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          article.title ?? 'missing title',
                          maxLines: 2,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 17),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          article.description ?? 'missing description',
                          maxLines: 3,
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
