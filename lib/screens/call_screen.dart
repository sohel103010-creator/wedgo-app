import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String otherUserId; final String otherName; final String callType; final String? incomingCallId;
  const CallScreen({super.key, required this.otherUserId, required this.otherName, required this.callType, this.incomingCallId});
  @override ConsumerState<CallScreen> createState() => _CallScreenState();
}
class _CallScreenState extends ConsumerState<CallScreen> {
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('কল - ${widget.otherName}')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('ভিডিও/অডিও কল শীঘ্রই আসছে', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ফিরে যান')),
      ])));
  }
}
