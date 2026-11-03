import 'package:flutter/material.dart';
import 'package:noise_suppression/noise_suppression.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _plugin = NoiseSuppression();
  String _text = 'Running the self check...';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    String text;
    try {
      final info = await _plugin.engineInfo();
      final report = await _plugin.selfCheck();
      text = '$info\n$report';
    } catch (error) {
      text = 'Failed: $error';
    }
    if (mounted) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('noise_suppression')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_text, key: const Key('report')),
        ),
      ),
    );
  }
}
