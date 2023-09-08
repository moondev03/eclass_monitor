import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'tab.dart';
import 'DatabaseHelper.dart';

void main() async {
  // 화면 세로 고정
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkCredentials(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        bool hasCredentials = snapshot.data ?? false;

        return MaterialApp(
          title: '',
          theme: ThemeData(
            fontFamily: 'omyu_pretty',
            useMaterial3: true,
            primarySwatch: Colors.blue,
          ),
          home: hasCredentials ? const TapPage() : LoginPage(),
        );
      },
    );
  }

  Future<bool> checkCredentials() async {
    DatabaseHelper db = DatabaseHelper();

    List<UserInfo> user = await db.getAllUserInfo();
    if (user.isNotEmpty) {
      print("${user[0].userid}로 로그인...");
      return true;
    } else {
      return false;
    }
  }
}
