import 'dart:convert'; import 'dart:math';

import 'package:flutter/material.dart'; import 'package:shared_preferences/shared_preferences.dart'; import 'package:intl/intl.dart';

void main() { runApp(HabitEpubApp());

class HabitEpubApp extends StatelessWidget { @override

Widget build(BuildContext context) {

return MaterialApp(

title: 'Habit Swipe',

theme: ThemeData(

primarySwatch: Colors.indigo,

home: HabitHomePage(),

class HabitHomePage extends StatefulWidget {

@override

_HabitHomePageState createState() => _HabitHomePageState();

class _HabitHomePageState extends State<HabitHomePage> { late PageController_pageController;

int_centerIndex = 12;

DateTime get_now => DateTime.now();

static const int_totalPages = 25;
@override void initState() { super.initState();

_pageController = PageController(initialPage: _centerIndex, viewportFraction: 0.95);

DateTime dateForPage(int pagelndex) { int offset = pagelndex - _centerIndex; DateTime m = DateTime(_now.year, _now.month + offset, 1); return m;

}

@override

Widget build(BuildContext context) {

return Scaffold(

appBar: AppBar(

title: Text('Your Habit Journal'), centerTitle: true,

body: SafeArea(

child: PageView.builder(

controller:_pageController,

itemCount: _totalPages,

itemBuilder: (context, index) {

final month = dateForPage(index);

return AnimatedMonthCard(

month: month,

pageController: _pageController,

        index: index,
                    );
                              },
                                      ),
                                            ),
                                                );
                                                  }
                                                  }

                                                  class AnimatedMonthCard extends StatefulWidget {
                                                    final DateTime month;
                                                      final PageController pageController;
                                                        final int index;

                                                          const AnimatedMonthCard({
                                                              required this.month,
                                                                  required this.pageController,
                                                                      required this.index,
                                                                        });

                                                                          @override
                                                                            _AnimatedMonthCardState createState() => _AnimatedMonthCardState();
                                                                            }

                                                                            class _AnimatedMonthCardState extends State<AnimatedMonthCard> {
                                                                              @override
                                                                                Widget build(BuildContext context) {
                                                                                    return AnimatedBuilder(
                                                                                          animation: widget.pageController,
                                                                                                builder: (context, child) {
                                                                                                        double value = 0;
                                                                                                                try {
                                                                                                                          value = (widget.pageController.page ?? widget.pageController.initialPage) - widget.index;
                                                                                                                                  } catch (_) {
                                                                                                                                            value = 0;
                                                                                                                                                    }
                                                                                                                                                            value = value.clamp(-1.0, 1.0);
                                                                                                                                                                    final rotationY = value * 0.6;
                                                                                                                                                                            final translate = value * -20.0;
                                                                                                                                                                                    final scale = 1 - (value.abs() * 0.04);
                                                                                                                                                                                            final opacity = 1 - (value.abs() * 0.35);
                                                                                                                                                                                            return Transform(
          alignment: value < 0 ? Alignment.centerLeft : Alignment.centerRight,
          transform: Matrix4.identity()
            ..translate(translate)
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotationY)
            ..scale(scale, scale),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: MonthPage(month: widget.month),
    );
  }
}

class MonthPage extends StatefulWidget {
  final DateTime month;
  const MonthPage({required this.month});

  @override
  _MonthPageState createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  late String monthKey;
  late int daysInMonth;
  List<String> habits = [
    "Wake up by 7",
    "Exercise 20m",
    "Read 15m",
    "No sugar",
  ];
  Map<String, List<bool>> checks = {};

  @override
  void initState() {
    super.initState();
    monthKey = DateFormat('yyyy-MM').format(widget.month);
    daysInMonth = DateTime(widget.month.year, widget.month.month + 1, 0).day;
    for (var h in habits) {
      checks[h] = List<bool>.filled(daysInMonth, false);
    }
    _load();
  }
Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('habit_$monthKey');
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        setState(() {
          habits = decoded.keys.toList();
          checks = decoded.map((k, v) {
            final arr = (v as List).map((e) => e as bool).toList();
            return MapEntry(k, List<bool>.from(arr));
          });
          _normalizeLength();
        });
      } catch (e) {}
    }
  }

  void _normalizeLength() {
    for (var k in habits) {
      if (checks[k]!.length != daysInMonth) {
        final old = checks[k]!;
        final newList = List<bool>.filled(daysInMonth, false);
        for (int i = 0; i < min(old.length, newList.length); i++) {
          newList[i] = old[i];
        }
        checks[k] = newList;
      }
    }
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final toStore = checks.map((k, v) => MapEntry(k, v));
    await sp.setString('habit_$monthKey', jsonEncode(toStore));
  }

  void _toggle(String habit, int dayIndex) {
    setState(() {
      checks[habit]![dayIndex] = !checks[habit]![dayIndex];
    });
    _save();
  }
void _addHabit() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Add habit'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  habits.add(text);
                  checks[text] = List<bool>.filled(daysInMonth, false);
                });
                _save();
              }
              Navigator.of(c).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _clearMonth() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Clear month data?'),
        content: Text('This will uncheck all habit marks for this month.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var h in habits) {
                  checks[h] = List<bool>.filled(daysInMonth, false);
                }
              });
              _save();
              Navigator.of(c).pop();
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
Widget _buildGrid() {
    final dayHeaders = List.generate(daysInMonth, (i) => i + 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          _headerRow(),
          SizedBox(height: 8),
          Material(
            elevation: 2,
            child: Row(
              children: [
                Container(width: 120, padding: EdgeInsets.all(8), child: Text('Habit')),
                ...dayHeaders.map((d) => Container(
                      width: 38,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('$d', style: TextStyle(fontSize: 12)),
                    )),
              ],
            ),
          ),
          ...habits.map((habit) {
            final row = checks[habit]!;
            return GestureDetector(
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('Remove habit?'),
                    content: Text('Remove "$habit" from this month.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(c).pop(), child: Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            checks.remove(habit);
                            habits.remove(habit);
                          });
                          _save();
                          Navigator.of(c).pop();
                        },
                        child: Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
              child: Material(
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      padding: EdgeInsets.all(8),
                      child: Text(habit, style: TextStyle(fontSize: 14)),
                    ),
                    ...List.generate(daysInMonth, (di) {
                      final done = row[di];
                      return InkWell(
                        onTap: () => _toggle(habit, di),
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: done ? Colors.indigo : Colors.transparent,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: done
                              ? Icon(Icons.check, size: 18, color: Colors.white)
                              : SizedBox.shrink(),
                        ),
                      );
                    })
                  ],
                ),
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _headerRow() {
    final localName = DateFormat.yMMMM().format(widget.month);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addHabit,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _clearMonth,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: habits.isEmpty ? Center(child: Text("No habits")) : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

