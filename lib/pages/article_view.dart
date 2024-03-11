import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:news_master/models/article_model.dart";
import "package:news_master/pages/article_web_view.dart";
import "package:sqflite/sqflite.dart";
// ignore: library_prefixes
import 'package:path/path.dart' as Path;

// ignore: must_be_immutable
class ArticleView extends StatefulWidget {
  ArticleModel article;
  bool is_favorite = false;

  ArticleView({required this.article});

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  bool _loadingDB = true;
  late Future<Database> favoriteArticles;
  List<ArticleModel> favoriteArticlesList = [];

  @override
  void initState() {
    getDatabase();
    super.initState();
  }

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

    favoriteArticlesList.forEach((element) {
      if (element.url == widget.article.url) {
        widget.is_favorite = true;
      }
    });

    //widget.is_favorite = favoriteArticlesList.contains(widget.article);

    setState(() {
      _loadingDB = false;
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

  @override
  Widget build(BuildContext context) {
    ArticleModel article = widget.article;

    return Scaffold(
      appBar: AppBar(
        title: Text('Article Preview'),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(widget.is_favorite ? Icons.star : Icons.star_outline),
              iconSize: 30,
              color: Colors.black,
              onPressed: () {
                setState(() {
                  widget.is_favorite = !widget.is_favorite;
                  if (widget.is_favorite) {
                    insertArticle(widget.article);
                  } else {
                    deleteArticle(widget.article);
                  }
                  print(widget.is_favorite);
                });
              }),
        ],
      ),
      body: (_loadingDB)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      article.title ?? 'invalid title',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(20),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                              imageUrl: article.urlToImage ?? '')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'By ${article.author}',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      article.description ?? 'invalid content',
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => ArticleWebView(
                                  article: article,
                                )));
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        child: Material(
                          borderRadius: BorderRadius.circular(20),
                          elevation: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                              child: Text(
                                "Open Full Article",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
