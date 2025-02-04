import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class MyCalendarPage extends StatefulWidget {
  const MyCalendarPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyCalendarPageState createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _events = {};

  DateTime? parseDate(String text, {int? defaultYear}) {
    final regex = RegExp(r'(?:(\d{4})年)?(\d{1,2})月(\d{1,2})日');
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final yearString = match.group(1);
    int year = yearString != null ? int.parse(yearString) : (defaultYear ?? DateTime.now().year);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime(year, month, day);
  }

  Future<void> scrapeEvents() async {
    final url = 'https://www.walkerplus.com/event_list/ar0313113/shibuya/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = html.parse(response.body);
      final eventListElements = document.querySelectorAll('div.m-mainlist-item');

      Map<DateTime, List<Map<String, String>>> events = {};

      for (var eventElement in eventListElements) {
        final titleElement = eventElement.querySelector('.m-mainlist-item__ttl');
        final title = titleElement?.text.trim() ?? 'タイトルなし';

        final dateElement = eventElement.querySelector('.m-mainlist-item-event__period');
        final dateText = dateElement?.text.trim().replaceAll('開催中', '').replaceAll('\n', '').trim() ?? '';

        if (!dateText.contains('～')) continue;
        final dateParts = dateText.split('～');
        final startDateText = dateParts[0].trim();
        final endDateText = dateParts[1].trim();

        final startDate = parseDate(startDateText);
        final endDate = parseDate(endDateText, defaultYear: startDate?.year);

        if (startDate == null || endDate == null) continue;

        // final imageElement = eventElement.querySelector('.m-mainlist-item__img img');
        // String imageUrl = imageElement?.attributes['src'] ?? '';

        // // URL が 'file://' で始まる場合は 'https://' に変換
        // if (imageUrl.startsWith('file://')) {
        //   imageUrl = imageUrl.replaceFirst('file://', 'https://');
        // }

        DateTime startKey = DateTime(startDate.year, startDate.month, startDate.day);
        events[startKey] = events[startKey] ?? [];
        // events[startKey]?.add({"title": title, "image": imageUrl});
         events[startKey]?.add({"title": title});

        DateTime endKey = DateTime(endDate.year, endDate.month, endDate.day);
        if (endKey != startKey) {
          events[endKey] = events[endKey] ?? [];
          // events[endKey]?.add({"title": title, "image": imageUrl});
          events[endKey]?.add({"title": title});
        }
      }

      setState(() {
        _events = events;
      });
    } else {
      throw Exception('Failed to load events');
    }
  }

  @override
  void initState() {
    super.initState();
    scrapeEvents();
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              DateTime eventDay = DateTime(day.year, day.month, day.day);
              return _events[eventDay] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      width: 16,
                      height: 16,
                      child: Center(
                        child: Text(
                          events.length > 1 ? '${events.length}' : '',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: (_events[selectedKey] != null && _events[selectedKey]!.isNotEmpty)
                  ? ListView.builder(
                      itemCount: _events[selectedKey]!.length,
                      itemBuilder: (context, index) {
                        final event = _events[selectedKey]![index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            // leading: event["image"]!.isNotEmpty
                            //   ? Image.network(event["image"]!, width: 50, height: 50, fit: BoxFit.cover)
                            //   : const Icon(Icons.event, size: 50),
                            title: Text(event["title"]!),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailPage(event: event),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('この日に予定はありません')),
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final Map<String, String> event;
  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event["title"]!)),
      body: Column(
        children: [
          // if (event["image"]!.isNotEmpty)
          //   Image.network(event["image"]!, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(event["title"]!, style: const TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}