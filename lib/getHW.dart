import 'dart:io';
// import 'dart:developer'; // log함수 사용하기 위함
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import 'DatabaseHelper.dart';

Future<List<HomeWorkInfo>> getHW() async {
  List<HomeWorkInfo> homeWorkData = [];

  // 세션을 유지하기 위한 객체 생성---------------------------------------------
  var client = http.Client();
  DatabaseHelper db = DatabaseHelper();
  List<UserInfo> futureUser = await db.getAllUserInfo();
  var userData = {
    "id": futureUser[0].userid,
    "passwrd": futureUser[0].password
  };

  // print(userData);
  var userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36";

  // SSO 페이지에서 Form을 통해 userCheck.do로 post요청-------------------------
  try {
    var userCheckURL = 'https://sso1.mju.ac.kr/mju/userCheck.do';
    var userCheckRes = await client.post(Uri.parse(userCheckURL),
        headers: {
          'User-Agent': userAgent,
          'Accept-Encoding': 'gzip, deflate',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Content-Length': '34',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: userData);

    var JSESSIONID2 = decodeSetCookie(userCheckRes.headers['set-cookie'] ?? "");
    // print(JSESSIONID2);

    Map<String, dynamic> user = jsonDecode(userCheckRes.body);
    if (user['error'] != "0000" && user['error'] != "VL-3130") {
      print("입력이 잘못되거나 유저 정보가 없습니다.");
      // throw Exception(user);
    } else {
      print("User Check 성공");

      // loginData ---------------------------------------------------
      var loginData = {
        "user_id": userData['id'],
        "user_pwd": userData['passwrd'],
        "redirect_uri": "https://home.mju.ac.kr/user/index.action"
      };

      // token2.do로 post요청 ------------------------------------------------------
      var token2URL = "https://sso1.mju.ac.kr/oauth2/token2.do";
      final token2Res = await client.post(Uri.parse(token2URL),
          headers: {
            'User-Agent': userAgent,
            'Accept-Encoding': 'gzip, deflate',
            'Accept': '*/*',
            'Connection': 'keep-alive',
            'Content-Length': '104',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': JSESSIONID2
          },
          body: loginData);
      // print("POST: token2URL\n${token2Res.headers}");

      var cookie = decodeSetCookie(token2Res.headers['set-cookie'] ?? "");
      // print(cookie);

      var indexURL = 'https://home.mju.ac.kr/user/index.action';
      var indexRes = await client.get(Uri.parse(indexURL), headers: {
        'User-Agent': userAgent,
        'Accept-Encoding': 'gzip, deflate',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Cookie': cookie
      });
      // print("GET: index.action\n${indexRes.headers}");

      var JSESSIONID1 = decodeSetCookie(indexRes.headers['set-cookie'] ?? "");
      var cookies = "$JSESSIONID1; $cookie";
      // print(cookies);

      // ECLASS 페이지 GET 요청 ----------------------------------------------------
      var lastURL =
          "https://home.mju.ac.kr/mainIndex/myHomeworkList.action?command=&tab=homework";
      var lastRes = await client.get(Uri.parse(lastURL),
          headers: {'User-Agent': userAgent, 'Cookie': cookies});

      if (lastRes.statusCode == 200) {
        // print(lastRes.headers);
        // log(lastRes.body); // print시에는 길이제한으로 출력이 제한됨

        var document = parser.parse(lastRes.body);
        homeWorkData = parsingHTML(document);

        List<String?> urls = CheckPage(document);

        for (var url in urls) {
          if (url != null) {
            url = "https://home.mju.ac.kr/mainIndex/$url";
            var addRes = await client.get(Uri.parse(url),
                headers: {'User-Agent': userAgent, 'Cookie': cookies});

            document = parser.parse(addRes.body);
            homeWorkData.addAll(parsingHTML(document));
          } else {
            continue;
          }
        }

        var data = notice(homeWorkData);
        data.then((value) {
          for (var e in value) {
            print(e.title);
          }
        });
      }
    }
  } catch (e) {
    print(e);
    if (e is RangeError) {
      HomeWorkInfo hw = HomeWorkInfo(
          title: "[알림] 과제 데이터가 없습니다.",
          date: "",
          submitter: "",
          period: "",
          state: "",
          score: "",
          url: "",
          comment: "");

      homeWorkData.add(hw);
    }
  }

  // 테스트용
  // for (var i = 0; i < homeWorkData.length; i++) {
  //   print('-------ITEM----------------');
  //   print(homeWorkData[i].title);
  //   print(homeWorkData[i].date);
  //   print(homeWorkData[i].submitter);
  //   print(homeWorkData[i].period);
  //   print(homeWorkData[i].state);
  //   print(homeWorkData[i].score);
  // }
  // print(homeWorkData[]);

  // 세션 종료
  client.close();

  return homeWorkData;
}

String decodeSetCookie(String setCookieValue) {
  var exp = RegExp(r'((?:[^,]|, )+)');
  setCookieValue = addSpaceAfterSemicolon(setCookieValue);
  Iterable<RegExpMatch> matches = exp.allMatches(setCookieValue);
  List<String> cookies = [];

  for (final m in matches) {
    // 쿠키 한개에 대한 디코딩 처리
    Cookie cookie = Cookie.fromSetCookieValue(m[0]!);
    String cookieString = '${cookie.name}=${cookie.value}';
    cookies.add(cookieString);
  }

  return cookies.join('; ');
}

String addSpaceAfterSemicolon(String input) {
  List<String> parts = input.split(';');
  List<String> modifiedParts = [];

  for (int i = 0; i < parts.length; i++) {
    String currentPart = parts[i];
    if (i < parts.length - 1 &&
        currentPart.isNotEmpty &&
        parts[i + 1].isNotEmpty &&
        parts[i + 1][0] != ' ') {
      modifiedParts.add('$currentPart;');
    } else {
      modifiedParts.add(currentPart);
    }
  }

  return modifiedParts.join(';');
}

List<HomeWorkInfo> parsingHTML(var document) {
  List<HomeWorkInfo> homeWorkData = [];
  HomeWorkInfo hw;

  var dlElements = document
      .getElementsByClassName("eClassList")[0]
      .getElementsByTagName('dl');
  print("해당 페이지 과제 수: ${dlElements.length}");

  // 각 dl 요소에서 class가 "date", "info", "comment"인 dd 태그를 찾아서 변수로 저장
  List<String> titles = [];
  List<String> dates = [];

  List<String> submitters = []; // 제출자
  List<String> periods = []; // 제출기간
  List<String> states = []; // 제출상태
  List<String> scores = []; // 평가점수
  List<String> urls = [];
  List<String> comments = [];

  for (var dl in dlElements) {
    var title = dl.getElementsByTagName('strong')[0].text.trim();
    var date = dl
        .getElementsByClassName('date')[0]
        .getElementsByTagName('span')[1]
        .text
        .trim();

    var info = dl
        .getElementsByClassName('information')[0]
        .getElementsByTagName('span');
    var submitter = info[1].text.trim();
    var period = info[3].text.trim();
    var state = info[5].text.trim();
    var score = info[7].text.trim();

    var url =
        dl.getElementsByTagName('dt')[0].children[0].attributes['href'].trim();

    var comment = dl.getElementsByClassName('comment')[0].text.trim();

    titles.add(title);
    dates.add(date);
    submitters.add(submitter);
    periods.add(period);
    states.add(state);
    scores.add(score);
    urls.add(url);
    comments.add(comment);
  }

  for (var i = 0; i < titles.length; i++) {
    hw = HomeWorkInfo(
        title: titles[i],
        date: dates[i],
        submitter: submitters[i],
        period: periods[i],
        state: states[i],
        score: scores[i],
        url: urls[i],
        comment: comments[i]);

    homeWorkData.add(hw);
  }

  return homeWorkData;
}

List<String?> CheckPage(var document) {
  List<dynamic> pages = document
      .getElementsByClassName("paging")[0] // ul
      .getElementsByTagName('li')[1] // li(최신), li(페이지들), li(끝)
      .getElementsByTagName('li');

  List<String?> hrefList = [];

  for (var i = 0; i < pages.length; i++) {
    var temp = document
        .getElementsByClassName("paging")[0] // ul
        .getElementsByTagName('li')[1] // li(최신), li(페이지들), li(끝)
        .getElementsByTagName('li')[i]
        .children;

    if (temp[0].localName == 'a') {
      hrefList.add(temp[0].attributes['href'].trim());
    } else {
      hrefList.add(null);
    }
  }

  return hrefList;
}

Future<List<HomeWorkInfo>> notice(List<HomeWorkInfo> homeWorkData) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  List<HomeWorkInfo> allInfo = await dbHelper.getAllHomeWorkInfo();
  List<HomeWorkInfo> newlyAddedData = [];

  for (var newInfo in homeWorkData) {
    bool isDuplicate = false;

    for (var oldInfo in allInfo) {
      if (newInfo.title == oldInfo.title &&
          newInfo.date == oldInfo.date &&
          newInfo.submitter == oldInfo.submitter &&
          newInfo.period == oldInfo.period &&
          newInfo.state == oldInfo.state &&
          newInfo.score == oldInfo.score &&
          newInfo.url == oldInfo.url &&
          newInfo.comment == oldInfo.comment) {
        isDuplicate = true;
        break;
      }
    }

    if (!isDuplicate) {
      newlyAddedData.add(newInfo);
    }
  }

  return newlyAddedData;
}
