import 'package:eclass/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'custom/CustomLinearProgressIndicator.dart';
import 'getHW.dart';
// import 'dart:developer'; // log함수 사용하기 위함

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<HomeWorkInfo>> _futureHW;
  late DatabaseHelper _dbHelper;
  List<HomeWorkInfo> hwData = [];
  late List<String> tags;
  int currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Map<String, double> submissionRates = {};
  Map<String, int> completedCount = {};

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _futureHW = _fetchHWData();
  }

  Future<List<HomeWorkInfo>> _fetchHWData() async {
    await _dbHelper.getAllHomeWorkInfo().then((value) async {
      if (value.isEmpty) {
        hwData = await getHW();

        for (var data in hwData) {
          await _dbHelper.insertHomeWorkInfo(data);
        }
        await _dbHelper.insertTagTable();
      } else {
        hwData = await _dbHelper.getAllHomeWorkInfo();
      }
    });

    tags = await _dbHelper.getTags();

    // 제출율 계산
    for (var tag in tags) {
      int completedCount = 0;
      int totalCount = 0;

      for (var hwInfo in hwData) {
        if (hwInfo.title.contains(tag)) {
          totalCount++;
          if (hwInfo.state == "제출완료") {
            completedCount++;
          }
        }
      }

      double submissionRate = totalCount > 0 ? completedCount / totalCount : 0;
      this.completedCount[tag] = completedCount;
      submissionRates[tag] = submissionRate;
    }

    return _dbHelper.getAllHomeWorkInfo();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 상단에 카드뷰 배치
    final cardWidth = screenWidth;
    final cardHeight = screenHeight * 0.3;

    return Scaffold(
      body: FutureBuilder<List<HomeWorkInfo>>(
        future: _futureHW,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 로딩 화면 표시
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.yellow,
              ),
            );
          } else if (snapshot.hasError) {
            // 에러 발생 시 처리
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return Column(
              children: [
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        return generateCardView(tags[index]);
                      },
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: snapshot.data!
                          .where((hwInfo) =>
                              hwInfo.title.contains(tags[currentIndex]))
                          .map((hwInfo) => ListTile(
                                title: Text(hwInfo.title),
                                subtitle: Text(hwInfo.state),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget generateCardView(String tag) {
    double borderRadius = 8.0;
    double submissionRate = submissionRates[tag] ?? 0;
    int completedCount = this.completedCount[tag] ?? 0;
    int totalCount =
        hwData.where((hwInfo) => hwInfo.title.contains(tag)).length;

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color.fromRGBO(226, 215, 167, 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            getSubmissionRateText(completedCount, totalCount),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: CustomLinearProgressIndicator(
              height: 10,
              value: submissionRate,
              backgroundColor: Colors.white,
              progressColor: const Color.fromRGBO(200, 222, 186, 1),
              borderRadius: borderRadius,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(submissionRate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String getSubmissionRateText(int completedCount, int totalCount) {
    return '제출율($completedCount/$totalCount)';
  }
}
