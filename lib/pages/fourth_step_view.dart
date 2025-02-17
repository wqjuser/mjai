import 'package:flutter/material.dart';

class FourthStepView extends StatefulWidget {
  const FourthStepView({super.key});

  @override
  State<FourthStepView> createState() => _FourthStepViewState();
}

class _FourthStepViewState extends State<FourthStepView> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('第四步的界面'),
    );
  }
}
