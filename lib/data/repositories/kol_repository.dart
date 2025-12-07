import 'package:drift/drift.dart';
import '../database/database.dart';

class KOLRepository {
  final AppDatabase _db;

  KOLRepository(this._db);

  /// 取得所有 KOL
  Future<List<KOL>> getAllKOLs() async {
    return await (_db.select(_db.kOLs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 新增 KOL
  Future<int> createKOL(KOLsCompanion kol) async {
    return await _db.into(_db.kOLs).insert(kol);
  }

  /// 依 ID 取得 KOL
  Future<KOL?> getKOLById(int id) async {
    return await (_db.select(_db.kOLs)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 更新 KOL
  Future<void> updateKOL(int id, KOLsCompanion kol) async {
    await (_db.update(_db.kOLs)..where((tbl) => tbl.id.equals(id))).write(kol);
  }

  /// 刪除 KOL
  Future<void> deleteKOL(int id) async {
    await (_db.delete(_db.kOLs)..where((tbl) => tbl.id.equals(id))).go();
  }
}
