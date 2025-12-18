import '../database/database.dart';

/// 貼文與 KOL 關聯資料
class PostWithKOL {
  final Post post;
  final KOL kol;

  const PostWithKOL({
    required this.post,
    required this.kol,
  });
}
