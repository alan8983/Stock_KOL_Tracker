import '../database/database.dart';

/// 貼文與 KOL 和 Stock 關聯資料
class PostWithDetails {
  final Post post;
  final KOL kol;
  final Stock stock;
  
  const PostWithDetails({
    required this.post,
    required this.kol,
    required this.stock,
  });
}
