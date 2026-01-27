import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String screenName;

  const PlaceholderScreen({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
      ),
      body: Center(
        child: Text(
          '$screenName screen is under construction.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
