import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';
import '../widgets/secure_screen.dart';

/// Verification Center: view status + submit selfie/video/identity.
/// Files go to the private verification-files bucket (never public).
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState
    extends ConsumerState<VerificationScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SecureScreen.set(true); // sensitive document screens
  }

  @override
  void dispose() {
    SecureScreen.set(false);
    super.dispose();
  }

  Future<void> _submitKind(String kind) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = ref.read(currentUserIdProvider)!;
      final file = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 70);
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      final path =
          'verifications/$uid/$kind-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supa.client.storage
          .from('verification-files')
          .upload(path, File(file.path));
      await Supa.client.from('verification_requests').insert({
        'user_id': uid,
        'kind': kind,
        'storage_path': path,
        'status': 'pending',
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'verification'))),
      body: uid == null
          ? Center(child: Text(tr(ref, 'empty')))
          : FutureBuilder<List<dynamic>>(
              future: Supa.client
                  .from('verification_requests')
                  .select()
                  .eq('user_id', uid)
                  .order('created_at', ascending: false),
              builder: (context, snap) {
                final rows =
                    (snap.data ?? []).cast<Map<String, dynamic>>();
                String statusOf(String kind) {
                  final r = rows.where(
                      (e) => e['kind'] == kind);
                  if (r.isEmpty) return 'none';
                  return r.first['status'] as String;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null)
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.red)),
                    for (final kind in [
                      'selfie',
                      'video',
                      'identity'
                    ])
                      Card(
                        child: ListTile(
                          title: Text(kind.toUpperCase()),
                          subtitle: Text(
                              '${tr(ref, 'pending')}: ${statusOf(kind)}'),
                          trailing: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2))
                              : FilledButton(
                                  onPressed: () =>
                                      _submitKind(kind),
                                  child:
                                      Text(tr(ref, 'send')),
                                ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
