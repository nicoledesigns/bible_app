import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String dailyVerse =
      "Philippians 4:13 — I can do all things through Christ who strengthens me.";
  final TextEditingController topicController = TextEditingController();
  final TextEditingController prayerController = TextEditingController();

  String? topicVerse;

  Map<String, String> topicVerseMap = {
    'love': '1 Corinthians 13:4 — Love is patient, love is kind...',
    'faith': 'Hebrews 11:1 — Faith is the assurance of things hoped for...',
    'hope': 'Jeremiah 29:11 — For I know the plans I have for you...',
    'forgiveness': 'Ephesians 4:32 — Be kind and compassionate...',
  };

  DateTime selectedMonth = DateTime.now();
  Map<String, String> prayerJournal = {};
  DateTime? selectedDate;

  void _searchTopicVerse() {
    final topic = topicController.text.trim().toLowerCase();
    setState(() {
      topicVerse = topicVerseMap[topic] ?? "Sorry, no verse found for that topic.";
    });
  }

  void _addPrayer() {
    if (selectedDate == null) return;
    final text = prayerController.text.trim();
    if (text.isEmpty) return;

    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);
    setState(() {
      prayerJournal[dateKey] = text;
      prayerController.clear();
    });
  }

  List<Widget> _buildWeekdayHeaders() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days
        .map(
          (day) => Center(
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildCalendar() {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    int startingWeekday = firstDayOfMonth.weekday;

    int weekdayOffset = startingWeekday - 1;

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 0; i < weekdayOffset; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDay = DateTime(selectedMonth.year, selectedMonth.month, day);
      final isToday = DateTime.now().day == day &&
          DateTime.now().month == selectedMonth.month &&
          DateTime.now().year == selectedMonth.year;
      final dateKey = DateFormat('yyyy-MM-dd').format(currentDay);
      final hasPrayer = prayerJournal.containsKey(dateKey) && prayerJournal[dateKey]!.isNotEmpty;

      dayWidgets.add(
        Material(
          color: isToday ? Colors.yellow[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                selectedDate = currentDay;
                prayerController.text = prayerJournal[dateKey] ?? '';
              });
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Day number top-right
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Prayer indicator bottom-left (open hands icon 🙌)
                  if (hasPrayer)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Icon(
                        Icons.volunteer_activism,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  @override
  void dispose() {
    prayerController.dispose();
    topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Bible App")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DAILY VERSE
            Center(
              child: Column(
                children: [
                  Text("📖 Daily Verse",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Card(
                    color: Colors.lightBlue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(dailyVerse, style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // PRAYER JOURNAL CALENDAR
            Text("🙏 Prayer Journal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year,
                          selectedMonth.month - 1);
                      selectedDate = null;
                      prayerController.clear();
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMM().format(selectedMonth),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year,
                          selectedMonth.month + 1);
                      selectedDate = null;
                      prayerController.clear();
                    });
                  },
                ),
              ],
            ),

            // Weekday Headers
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              children: _buildWeekdayHeaders(),
            ),

            // Calendar Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              children: _buildCalendar(),
            ),

            if (selectedDate != null) ...[
              SizedBox(height: 16),
              Text(
                'Write prayer for ${DateFormat.yMMMd().format(selectedDate!)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                controller: prayerController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter your prayer...",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Add Prayer"),
                  onPressed: () {
                    _addPrayer();
                    FocusScope.of(context).unfocus(); // dismiss keyboard
                  },
                ),
              ),
            ],

            SizedBox(height: 32),

            // TOPIC VERSE LOOKUP
            Text("🔍 Bible Verse by Topic",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Enter a topic (e.g., love, faith, hope)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchTopicVerse,
                ),
              ),
            ),
            SizedBox(height: 12),
            if (topicVerse != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(topicVerse!, style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
