import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:expressions/expressions.dart';

void main() {
  runApp(MyCalculatorApp());
}

class MyCalculatorApp extends StatefulWidget {
  @override
  _MyCalculatorAppState createState() => _MyCalculatorAppState();
}

class _MyCalculatorAppState extends State<MyCalculatorApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Color.fromARGB(255, 231, 231, 231),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.orange,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(20),
          ),
        ),
        textTheme: TextTheme(
          headline4: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
          button: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color.fromARGB(255, 22, 22, 22),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.teal,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(20),
          ),
        ),
        textTheme: TextTheme(
          headline4: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
          button: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: SplashScreen(
        onThemeToggle: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  SplashScreen({required this.onThemeToggle});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CalculatorPage(onThemeToggle: widget.onThemeToggle)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Awesome Calc',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  CalculatorPage({required this.onThemeToggle});

  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _output = "0";
  String _expression = "";
  bool _isNewCalculation = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound() async {
    await _audioPlayer
        .play(AssetSource('click.mp3')); // Ensure 'click.mp3' is in your assets
  }

  void _buttonPressed(String buttonText) {
    _playSound();
    setState(() {
      if (buttonText == "C") {
        _output = "0";
        _expression = "";
        _isNewCalculation = true;
      } else if (buttonText == "=") {
        try {
          _output = _calculateResult(_expression);
          _expression = _output; // Keep the result for next operations
          _isNewCalculation = true;
        } catch (e) {
          _output = "Error";
        }
      } else if (buttonText == "⌫") {
        if (_expression.isNotEmpty) {
          // Remove the last character
          _expression = _expression.substring(0, _expression.length - 1);
          if (_expression.isEmpty) {
            _output = "0";
          } else {
            _output = _expression;
          }
          // Prevent invalid input like multiple operators in a row
          if (_expression.isNotEmpty &&
              RegExp(r'[+\-*/]')
                  .hasMatch(_expression[_expression.length - 1])) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        }
      } else {
        if (_isNewCalculation) {
          // After '=' or 'C', start a new expression
          if (RegExp(r'\d').hasMatch(buttonText)) {
            _expression = buttonText;
            _output = buttonText;
          } else if (RegExp(r'[+\-*/]').hasMatch(buttonText)) {
            // Allow operator to continue the expression after '='
            _expression += buttonText;
            _output = _expression;
          }
          _isNewCalculation = false;
        } else {
          // Prevent multiple operators
          if (RegExp(r'[+\-*/]').hasMatch(buttonText) &&
              _expression.isNotEmpty &&
              RegExp(r'[+\-*/]')
                  .hasMatch(_expression[_expression.length - 1])) {
            return;
          }

          _expression += buttonText;
          _output = _expression;
          _isNewCalculation = false;
        }
      }
    });
  }

  String _calculateResult(String expression) {
    try {
      final expr = Expression.parse(expression);
      final evaluator = const ExpressionEvaluator();
      final result = evaluator.eval(expr, {});
      return result.toString();
    } catch (e) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                child: Text(
                  _output,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
            ),
            _buildButtonGrid(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onThemeToggle,
        child: Icon(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.wb_sunny
              : Icons.nightlight_round,
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Container(
      color: Colors.transparent,
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.all(8.0),
        children: <Widget>[
          _buildButton("7"),
          _buildButton("8"),
          _buildButton("9"),
          _buildButton("/"),
          _buildButton("4"),
          _buildButton("5"),
          _buildButton("6"),
          _buildButton("*"),
          _buildButton("1"),
          _buildButton("2"),
          _buildButton("3"),
          _buildButton("-"),
          _buildButton("C"),
          _buildButton("0"),
          _buildButton("="),
          _buildButton("+"),
          _buildButton("⌫"),
        ],
      ),
    );
  }

  Widget _buildButton(String buttonText) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => _buttonPressed(buttonText),
        child: Text(
          buttonText,
          style: Theme.of(context).textTheme.button,
        ),
      ),
    );
  }
}
