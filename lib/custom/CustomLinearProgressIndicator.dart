import 'package:flutter/material.dart';

class CustomLinearProgressIndicator extends StatefulWidget {
  final double value;
  final Color backgroundColor;
  final Color progressColor;
  final double borderRadius;
  final double height;

  const CustomLinearProgressIndicator({
    Key? key,
    required this.value,
    required this.backgroundColor,
    required this.progressColor,
    required this.borderRadius,
    required this.height,
  }) : super(key: key);

  @override
  _CustomLinearProgressIndicatorState createState() =>
      _CustomLinearProgressIndicatorState();
}

class _CustomLinearProgressIndicatorState
    extends State<CustomLinearProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LinearProgressIndicator(
        minHeight: widget.height,
        value: widget.value,
        backgroundColor: widget.backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(widget.progressColor),
      ),
    );
  }
}
