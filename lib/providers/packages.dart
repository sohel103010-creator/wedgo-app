// Packages + subscription state. Pricing is loaded from Supabase,
// so admin changes apply without an app release.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package.dart';
import '../services/supabase_client.dart';

final packagesProvider = FutureProvider<List<Package>>((ref) async {
  final rows = await Supa.client
      .from('packages')
      .select()
      .eq('is_active', true)
      .order('sort_order');
  return (rows as List).map((e) => Package.fromJson(e)).toList();
});
