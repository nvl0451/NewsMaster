class ArticleModel {
  String? author;
  String? title;
  String? description;
  String? url;
  String? urlToImage;
  String? content;

  ArticleModel(
      {this.author,
      this.title,
      this.description,
      this.url,
      this.urlToImage,
      this.content});

  ArticleModel.fromList(List<String> articleStringList) {
    author = articleStringList[0];
    title = articleStringList[1];
    description = articleStringList[2];
    url = articleStringList[3];
    urlToImage = articleStringList[4];
    content = articleStringList[5];
  }

  Map<String, Object?> toMap() {
    return {
      'author': author,
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'content': content
    };
  }

  List<String> toStringList() {
    return [
      author ?? '',
      title ?? '',
      description ?? '',
      url ?? '',
      urlToImage ?? '',
      content ?? ''
    ];
  }
}
