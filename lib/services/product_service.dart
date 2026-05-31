import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/product.dart';

final _client = Supabase.instance.client;

Future<String?> getOrCreateStoreForUser(String userId) async {
  try {
    final dynamic existing = await _client.from('stores').select().eq('user_id', userId).maybeSingle();
    if (existing is Map<String, dynamic> && existing['id'] != null) {
      return existing['id'].toString();
    }

    // create a basic store record if none exists
    final slugBase = 's-${userId.replaceAll('-', '').substring(0, 8)}';
    final createData = {
      'user_id': userId,
      'name': 'متجر ${userId.substring(0, 6)}',
      'slug': slugBase,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final dynamic created = await _client.from('stores').insert(createData).select().maybeSingle();
      if (created is Map<String, dynamic> && created['id'] != null) return created['id'].toString();
    } catch (e) {
      debugPrint('create store conflict or error: $e');
      // on conflict, try to fetch again
      final dynamic again = await _client.from('stores').select().eq('user_id', userId).maybeSingle();
      if (again is Map<String, dynamic> && again['id'] != null) return again['id'].toString();
    }
  } catch (e) {
    debugPrint('getOrCreateStoreForUser error: $e');
  }
  return null;
}

String _slugify(String input) {
  var s = input.toLowerCase();
  // replace spaces and underscores with dash
  s = s.replaceAll(RegExp(r'[\s_]+'), '-');
  // remove non-alphanumeric/dash
  s = s.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  if (s.isEmpty) s = 'store';
  if (s.length > 40) s = s.substring(0, 40);
  return s;
}

Future<Store?> ensureStoreForUser(String userId) async {
  try {
    final dynamic existing = await _client.from('stores').select().eq('user_id', userId).maybeSingle();
    if (existing is Map<String, dynamic> && existing['id'] != null) {
      return Store.fromMap(Map<String, dynamic>.from(existing));
    }

    // propose a name + slug
    final proposedName = 'متجر ${userId.substring(0, 6)}';
    var baseSlug = _slugify(proposedName);

    // ensure uniqueness
    var candidate = baseSlug;
    var i = 0;
    while (true) {
      final q = await _client.from('stores').select('id').eq('slug', candidate).maybeSingle();
      if (q == null) break;
      i++;
      candidate = '${baseSlug}-$i';
      if (i > 50) break; // safety
    }

    final createData = {
      'user_id': userId,
      'name': proposedName,
      'slug': candidate,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final dynamic created = await _client.from('stores').insert(createData).select().maybeSingle();
      if (created is Map<String, dynamic>) return Store.fromMap(Map<String, dynamic>.from(created));
    } catch (e) {
      debugPrint('ensureStoreForUser create error: $e');
      final dynamic again = await _client.from('stores').select().eq('user_id', userId).maybeSingle();
      if (again is Map<String, dynamic>) return Store.fromMap(Map<String, dynamic>.from(again));
    }
  } catch (e) {
    debugPrint('ensureStoreForUser error: $e');
  }
  return null;
}

Future<List<Product>> fetchProductsByStoreId(String storeId) async {
  try {
    final dynamic res = await _client.from('products').select().eq('store_id', storeId).order('created_at', ascending: false);
    List<dynamic> list;
    try {
      list = res as List<dynamic>;
    } catch (_) {
      try {
        list = (res as dynamic).data as List<dynamic>;
      } catch (_) {
        return [];
      }
    }
    return list.map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map<String, dynamic>))).toList();
  } catch (e) {
    debugPrint('fetchProductsByStoreId error: $e');
    return [];
  }
}

Future<String?> getStoreIdForUser(String userId) async {
  try {
    final dynamic storeRes = await _client.from('stores').select('id').eq('user_id', userId).maybeSingle();
    if (storeRes is Map<String, dynamic>) {
      return storeRes['id']?.toString();
    }
  } catch (e) {
    debugPrint('getStoreIdForUser error: $e');
  }
  return null;
}

Future<List<Product>> fetchProductsByUserId(String userId) async {
  try {
    final storeId = await getStoreIdForUser(userId);
    if (storeId == null) return [];
    return await fetchProductsByStoreId(storeId);
  } catch (e) {
    debugPrint('fetchProductsByUserId error: $e');
    return [];
  }
}

Future<List<Product>> fetchProductsBySlug(String slug) async {
  try {
    final dynamic storeRes = await _client.from('stores').select().eq('slug', slug).maybeSingle();
    if (storeRes == null) return [];
    final storeId = (storeRes is Map<String, dynamic>) ? storeRes['id']?.toString() : null;
    if (storeId == null) return [];
    return await fetchProductsByStoreId(storeId);
  } catch (e) {
    debugPrint('fetchProductsBySlug error: $e');
    return [];
  }
}
