import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  DatabaseHelper.internal();

  Future<Database?> initDatabase() async {
    String path = join(await getDatabasesPath(), 'home_work_info.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          '''
          CREATE TABLE HomeWorkInfo(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            date TEXT,
            submitter TEXT,
            period TEXT,
            state TEXT,
            score TEXT,
            url TEXT,
            comment TEXT,
            UNIQUE(title, date, submitter) ON CONFLICT IGNORE
          )
          ''',
        );

        await db.execute(
          '''
          CREATE TABLE UserInfo(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userid TEXT,
            password TEXT
          )
          ''',
        );

        await db.execute(
          '''
          CREATE TABLE IF NOT EXISTS Tag (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tag TEXT UNIQUE
          )
          ''',
        );
      },
    );
    return _database;
  }

  Future<void> insertHomeWorkInfo(HomeWorkInfo info) async {
    final db = await database;
    await db!.insert('HomeWorkInfo', info.toMap());
  }

  Future<List<HomeWorkInfo>> getAllHomeWorkInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('HomeWorkInfo');
    return List.generate(maps.length, (i) {
      return HomeWorkInfo.fromMap(maps[i]);
    });
  }

  Future<void> dropDB() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'home_work_info.db');
    print(dbPath);
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
      print('데이터베이스 삭제 완료.');
    } else {
      print('데이터베이스가 존재하지 않습니다.');
    }
  }

  Future<void> deleteAllHomeWorkInfo() async {
    final db = await database;
    await db!.delete('HomeWorkInfo');
    print('데이터 삭제 완료.');
  }

  Future<void> insertUserInfo(UserInfo info) async {
    final db = await database;
    await db!.insert('UserInfo', info.toMap());
  }

  Future<void> deleteUserInfo() async {
    final db = await database;
    await db!.delete('UserInfo');
    print('로그아웃');
  }

  Future<List<UserInfo>> getAllUserInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('UserInfo');
    return List.generate(maps.length, (i) {
      return UserInfo.fromMap(maps[i]);
    });
  }

  // -----------------------------------------------------------------------
  Future<void> insertTagTable() async {
    final db = await database;

    final List<HomeWorkInfo> homeWorkInfos = await getAllHomeWorkInfo();
    for (final info in homeWorkInfos) {
      final String title = info.title;
      final RegExp regex = RegExp(r'\[(.*?)\]');
      final Match? match = regex.firstMatch(title);
      if (match != null) {
        final String tag = match.group(1) ?? '';
        await db!.insert(
          'Tag',
          {'tag': tag},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> deleteTags() async {
    final db = await database;
    await db!.delete('Tag');
    print('태그 삭제');
  }

  Future<List<String>> getTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('Tag');
    return List.generate(maps.length, (i) {
      return maps[i]['tag'] as String;
    });
  }

  Future<List<HomeWorkInfo>> getHomeWorkInfoByTag(List<String> tags) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'HomeWorkInfo',
      where: 'tags LIKE ?',
      whereArgs: ['%${tags.join(',')}%'],
    );
    return List.generate(maps.length, (i) {
      return HomeWorkInfo.fromMap(maps[i]);
    });
  }
}

class HomeWorkInfo {
  final String title;
  final String date;
  final String submitter;
  final String period;
  final String state;
  final String score;
  final String url;
  final String comment;

  HomeWorkInfo({
    required this.title,
    required this.date,
    required this.submitter,
    required this.period,
    required this.state,
    required this.score,
    required this.url,
    required this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'submitter': submitter,
      'period': period,
      'state': state,
      'score': score,
      'url': url,
      'comment': comment,
    };
  }

  factory HomeWorkInfo.fromMap(Map<String, dynamic> map) {
    return HomeWorkInfo(
      title: map['title'],
      date: map['date'],
      submitter: map['submitter'],
      period: map['period'],
      state: map['state'],
      score: map['score'],
      url: map['url'],
      comment: map['comment'],
    );
  }
}

class UserInfo {
  final String userid;
  final String password;

  UserInfo({
    required this.userid,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'userid': userid,
      'password': password,
    };
  }

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      userid: map['userid'],
      password: map['password'],
    );
  }
}
