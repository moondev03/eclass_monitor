import 'package:eclass/DatabaseHelper.dart';
import 'package:eclass/getHW.dart';
import 'package:eclass/tab.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                DatabaseHelper dbHelper = DatabaseHelper();
                dbHelper.deleteUserInfo();
                dbHelper.deleteAllHomeWorkInfo();
                dbHelper.deleteTags();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                    (route) => false);
              },
              child: const Text('로그아웃'),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.pink,
                      ),
                    );
                  },
                );

                DatabaseHelper dbHelper = DatabaseHelper();
                await dbHelper.deleteAllHomeWorkInfo();
                await dbHelper.deleteTags();
                List<HomeWorkInfo> hwData = await getHW();

                for (var i = 0; i < hwData.length; i++) {
                  var data = hwData[i];
                  await dbHelper.insertHomeWorkInfo(data);
                }

                await dbHelper.insertTagTable();

                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[Text("데이터를 새로 불러왔습니다.")],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TapPage(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text("확인"),
                        )
                      ],
                    );
                  },
                );
              },
              child: const Text('데이터 새로 받기'),
            ),
            ElevatedButton(
              onPressed: () {
                const url =
                    'https://sso1.mju.ac.kr/login.do?redirect_uri=https://home.mju.ac.kr/user/index.action';

                _launchUrl(Uri.parse(url));
              },
              child: const Text("ECLASS로 이동"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(_url) async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}
