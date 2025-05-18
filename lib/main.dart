import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DateGame(),
    );
  }
}

class DateGame extends StatefulWidget {
  const DateGame({super.key});

  @override
  _DateGameState createState() => _DateGameState();
}

class _DateGameState extends State<DateGame> {
  int _day = 0;
  int _month = 0;
  int _year0 = 0;
  int _year = 0;
  int _cent = 0;
  int _monthValue = 0;
  int _yearValue = 0;
  int _centValue = 0;
  int _leapValue = 0;
  bool _leap = false;
  int _correctAnswer = 0;
  String _resultText = '';
  double _timeTaken = 0.0;
  late DateTime _startTime;
  bool _answered = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _responseHistory = [];

  @override
  void initState() {
    super.initState();
    _generateProblem();
    _loadHistory();
  }

  void _generateProblem() {
    final random = Random();
    // Generate a random date
    _year0 = (random.nextInt(200) + 1900); // Year is between 1900 and 2100
    _month = random.nextInt(12) + 1; // Month is between 1 and 12
    switch (_month) {
      case 1 || 3 || 5 || 7 || 8 || 10 || 12:
        _day = random.nextInt(31) + 1;
        break;
      case 2:
        _day = random.nextInt(28) + 1;
        break;
      case 4 || 6 || 9 || 11:
        _day = random.nextInt(30) + 1;
        break;
    }

    _year = _year0 % 100;
    _cent = ((_year0 - _year) / 100).toInt();
    if ((_year % 4 == 0 && _year != 0) || (_year == 0 && _cent % 4 == 0)) {
      _leap = true;
    } else {
      _leap = false;
    }
    _yearValue = (((_year - (_year % 4)) / 4) + _year).toInt();

    switch (_cent % 4) {
      case 0:
        _centValue = 2;
      case 1:
        _centValue = 0;
      case 2:
        _centValue = 5;
      case 3:
        _centValue = 3;
    }

    switch (_month) {
      case 2 || 3 || 11:
        _monthValue = 0;
      case 6:
        _monthValue = 1;
      case 9 || 12:
        _monthValue = 2;
      case 4 || 7:
        _monthValue = 3;
      case 1 || 10:
        _monthValue = 4;
      case 5:
        _monthValue = 5;
      case 8:
        _monthValue = 6;
    }
    if (_month < 3 && _leap == true) {
      _leapValue = 1;
    } else {
      _leapValue = 0;
    }

    _correctAnswer =
        ((_centValue + _yearValue + _monthValue + _day - _leapValue) % 7)
            .toInt();

    setState(() {
      _resultText = '';
      _answered = false;
      _startTime = DateTime.now();
    });
  }

  void _checkAnswer(int userAnswer) async {
    if (_answered) return; // Ignore additional presses
    setState(() {
      _answered = true;
      _timeTaken =
          DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
      if (userAnswer == _correctAnswer) {
        _resultText = 'Correct! Time: ${_timeTaken.toStringAsFixed(2)}';
      } else {
        _resultText =
            'Incorrect. Correct answer was $_correctAnswer. Time: ${_timeTaken.toStringAsFixed(2)}';
      }
    });

    try {
      await _dbHelper.insertResponse({
        'timestamp': DateTime.now().toIso8601String(),
        'time_taken': _timeTaken,
        'is_correct': userAnswer == _correctAnswer ? 1 : 0,
      });
    } catch (e) {
      print('Error saving time: $e');
    }

    try {
      await _dbHelper.getResponseCount();
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _loadHistory() async {
    final history = await _dbHelper.getResponses();
    setState(() {
      _responseHistory = history;
    });
  }

  Widget _buildDigitButton(int digit) {
    return ElevatedButton(
      onPressed: _answered ? null : () => _checkAnswer(digit),
      child: Text('$digit', style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day of the Week Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_day/$_month/$_year0',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _resultText,
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Digit buttons in a 2x5 grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: List.generate(7, (index) => _buildDigitButton(index)),
            ),
            const SizedBox(height: 20),
            if (_answered)
              ElevatedButton(
                onPressed: () => setState(() => _generateProblem()),
                child: const Text(
                  'Next Problem',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Response History',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _dbHelper.getResponses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No responses yet'));
                        }
                        final responses = snapshot.data!;
                        return ListView.builder(
                          itemCount: responses.length,
                          itemBuilder: (context, index) {
                            final response = responses[index];
                            return ListTile(
                              title: Text(
                                'Time: ${response['time_taken'].toStringAsFixed(2)}s, '
                                '${response['is_correct'] == 1 ? 'Correct' : 'Incorrect'}',
                              ),
                              subtitle: Text(response['timestamp']),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
