import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'DatabaseHelper.dart';
import 'tab.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '아이디',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '패스워드',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String id = _idController.text;
                String password = _passwordController.text;

                // showDialog(
                //   context: context,
                //   barrierDismissible: false, // 사용자가 대화 상자 외부를 터치해도 닫히지 않음
                //   builder: (BuildContext context) {
                //     return const Center(
                //       child: CircularProgressIndicator(
                //         color: Colors.pink,
                //       ), // 로딩 표시기
                //     );
                //   },
                // );

                var flag = false;
                await UserCheck(id, password).then((value) {
                  flag = value;
                  // Navigator.pop(context); // 로딩 창 닫기
                });

                if (flag == false) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: const Text("로그인 정보가 잘못되었습니다."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('닫기'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TapPage()),
                  );
                }
              },
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> UserCheck(String id, String pw) async {
    var client = http.Client();
    var userData = {"id": id, "passwrd": pw};
    var userCheckURL = 'https://sso1.mju.ac.kr/mju/userCheck.do';
    var userCheckRes =
        await client.post(Uri.parse(userCheckURL), body: userData);

    Map<String, dynamic> user = jsonDecode(userCheckRes.body);
    if (user['error'] != "0000" && user['error'] != "VL-3130") {
      print("입력이 잘못되거나 유저 정보가 없습니다.");

      client.close();
      return false;
    } else {
      print("User Check 성공");

      DatabaseHelper db = DatabaseHelper();
      UserInfo user = UserInfo(userid: id, password: pw);
      await db.insertUserInfo(user);

      print("DB에 로그인 정보 저장");
      client.close();
      return true;
    }
  }
}
