import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:news_master/models/article_model.dart';
import 'package:news_master/pages/article_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
// Variables

  List<ArticleModel> articles = [];
  bool _loadingFavs = true;

  late Future<Database> favoriteArticles;
  List<ArticleModel> favoriteArticlesList = [];
  int favoriteArticlesAmount = 0;

  // State init

  @override
  void initState() {
    getDatabase();
    super.initState();
  }

  // Database section

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
    articles = favoriteArticlesList;
    print(favoriteArticlesList);

    favoriteArticlesAmount = favoriteArticlesList.length;

    setState(() {
      _loadingFavs = false;
    });
  }

  Future<List<ArticleModel>> retrieveFavorites() async {
    final db = await favoriteArticles;
    final List<Map<String, Object?>> articleMaps = await db.query('favorites');
    return [
      for (final {
            'author': author as String,
            'title': title as String,
            'description': description as String,
            'url': url as String,
            'urlToImage': urlToImage as String,
            'content': content as String
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

// Navigation section

  Future<void> _navigateToArticleView(ArticleModel articleModel) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ArticleView(article: articleModel)));

    if (!context.mounted) return;

    getDatabase();
  }

// Build section

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorite Articles"),
      ),
      body: (_loadingFavs)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                child: ListView.builder(
                    physics: ClampingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: articles.length,
                    itemBuilder: ((context, index) {
                      return buildBlogTile(articles[index]);
                    })),
              ),
            ),
    );
  }

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
