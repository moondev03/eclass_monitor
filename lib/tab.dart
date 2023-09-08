import 'package:flutter/material.dart';

import 'filter.dart';
import 'home.dart';
import 'setting.dart';

class TapPage extends StatefulWidget {
  const TapPage({Key? key}) : super(key: key);

  @override
  State<TapPage> createState() => _TapPageState();
}

class _TapPageState extends State<TapPage>
    with AutomaticKeepAliveClientMixin<TapPage> {
  int _selectedIndex = 1;

  final List<Widget> _widgetOptions = <Widget>[
    const FilterPage(),
    const MyHomePage(),
    const SettingPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 메인 위젯
  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin에서 필요한 super 호출

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.filter),
            label: '과목 별',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightGreen,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}
