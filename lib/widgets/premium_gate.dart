// Shown when a member taps a premium-locked profile/feature.
// Never reveals the underlying content.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';

class PremiumGate {
  static Future<void> show(BuildContext context, WidgetRef ref,
      {String? messageKey}) {
    final t = (String k) => tr(ref, k);
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('premium_required')),
        content: Text(messageKey != null ? t(messageKey) : t('premium_locked_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscribe');
            },
            child: Text(t('subscribe')),
          ),
        ],
      ),
    );
  }
}
