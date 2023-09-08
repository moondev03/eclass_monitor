import 'package:flutter/material.dart';
import 'DatabaseHelper.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key});

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage>
    with AutomaticKeepAliveClientMixin<FilterPage> {
  DatabaseHelper dbHelper = DatabaseHelper();
  List<String> selectedTags = []; // 선택된 태그 목록을 저장할 리스트
  List<String> tags = [];
  List<HomeWorkInfo> allHomeworks = []; // 모든 과제 정보를 저장할 리스트
  List<HomeWorkInfo> filteredHomeworks = []; // 필터링된 과제 정보를 저장할 리스트
  bool showConditions = false; // 조건을 보여줄지 여부를 저장하는 변수

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    print('init 시작');
    super.initState();
  }

  Widget _buildHomeworkCard(HomeWorkInfo hw) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          hw.title,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '등록날짜: ${hw.date}\n제출자: ${hw.submitter}\n제출기간: ${hw.period}\n제출상태: ${hw.state}\n평가점수: ${hw.score}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('강의 별 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                showConditions = !showConditions;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (showConditions)
            Container(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<String>>(
                future: dbHelper.getTags(), // 비동기로 태그 목록을 불러옴
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text('오류가 발생했습니다.'),
                    );
                  } else {
                    tags = snapshot.data!;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: tags.map((tag) {
                          return FilterChip(
                            label: Text(tag),
                            selected: selectedTags.contains(tag),
                            onSelected: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<HomeWorkInfo>>(
              future: dbHelper.getAllHomeWorkInfo(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<HomeWorkInfo>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('오류가 발생했습니다.'),
                  );
                } else {
                  allHomeworks = snapshot.data!;
                  filteredHomeworks = allHomeworks.where((e) {
                    return selectedTags.any((tag) => e.title.contains(tag));
                  }).toList();

                  return filteredHomeworks.isEmpty
                      ? ListView.builder(
                          itemCount: allHomeworks.length,
                          itemBuilder: (context, index) {
                            HomeWorkInfo hw = allHomeworks[index];
                            return _buildHomeworkCard(hw);
                          },
                        )
                      : ListView.builder(
                          itemCount: filteredHomeworks.length,
                          itemBuilder: (context, index) {
                            HomeWorkInfo hw = filteredHomeworks[index];
                            return _buildHomeworkCard(hw);
                          },
                        );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
