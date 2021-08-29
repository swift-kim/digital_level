import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(MaterialApp(home: MainPage()));
}

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late StreamSubscription<AccelerometerEvent> _listener;
  Queue<AccelerometerEvent> _recentEvents = Queue();
  double _xPosition = 0;
  double _yPosition = 0;
  double _xDegree = 0;
  double _yDegree = 0;

  @override
  void initState() {
    super.initState();

    Wakelock.enable();

    _listener = accelerometerEvents.listen(_updatePosition);
  }

  void _updatePosition(AccelerometerEvent event) {
    _recentEvents.add(event);
    if (_recentEvents.length > 5) {
      _recentEvents.removeFirst();
    }
    setState(() {
      final num xSum = _recentEvents.map((e) => e.x).reduce((a, b) => a + b);
      final num ySum = _recentEvents.map((e) => e.y).reduce((a, b) => a + b);
      final num zSum = _recentEvents.map((e) => e.z).reduce((a, b) => a + b);
      final num xRadian = atan(xSum / zSum);
      final num yRadian = atan(ySum / zSum);
      _xPosition = xSum / _recentEvents.length / 10;
      _yPosition = -ySum / _recentEvents.length / 10;
      _xDegree = 180 * xRadian / pi;
      _yDegree = 180 * yRadian / pi;
    });
  }

  @override
  void dispose() {
    super.dispose();

    _listener.cancel();
  }

  double get _backgroundOpacity {
    const num threshold = 0.01;
    const num exponent = 3;
    final num distance = pow(_xPosition, 2) + pow(_yPosition, 2);
    final num saturation = max(0, threshold - distance) / threshold;
    return pow(saturation, exponent).toDouble();
  }

  Color get _backgroundColor {
    return Color.alphaBlend(
      Colors.tealAccent.shade700.withOpacity(_backgroundOpacity),
      Colors.white10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(color: _backgroundColor),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Align(
          alignment: Alignment(_xPosition, _yPosition),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Align(
          alignment: Alignment(0.66, -0.66),
          child: TextBox('x\n${_xDegree.toStringAsFixed(1)}°'),
        ),
        Align(
          alignment: Alignment(-0.62, 0.62),
          child: TextBox('y\n${_yDegree.toStringAsFixed(1)}°'),
        ),
        CrossScope(color: Colors.white.withOpacity(0.8)),
      ],
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: Colors.white.withOpacity(0.8),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class CrossScope extends StatelessWidget {
  const CrossScope({
    Key? key,
    this.color = Colors.white,
    this.length = 10,
  }) : super(key: key);

  final Color? color;
  final int length;
  final double thickness = 2;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Row(
            children: [
              Flexible(
                flex: length,
                child: Divider(color: color, thickness: thickness),
              ),
              Flexible(
                flex: 2 * (100 - length),
                child: Container(),
              ),
              Flexible(
                flex: length,
                child: Divider(color: color, thickness: thickness),
              ),
            ],
          ),
        ),
        Center(
          child: Column(
            children: [
              Flexible(
                flex: length,
                child: VerticalDivider(color: color, thickness: thickness),
              ),
              Flexible(
                flex: 2 * (100 - length),
                child: Container(),
              ),
              Flexible(
                flex: length,
                child: VerticalDivider(color: color, thickness: thickness),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
