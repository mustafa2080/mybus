import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Advanced caching service with multiple cache levels and smart eviction
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache configuration
  static const int _maxMemoryCacheSize = 200;
  static const int _maxPersistentCacheSize = 500;
  static const Duration _defaultExpiration = Duration(minutes: 5);
  static const Duration _longExpiration = Duration(hours: 1);
  static const Duration _shortExpiration = Duration(minutes: 1);

  // Memory cache (fastest access)
  final Map<String, CacheEntry> _memoryCache = {};
  
  // Cache hit/miss statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Cache entry with metadata
  class CacheEntry {
    final dynamic data;
    final DateTime timestamp;
    final Duration expiration;
    final int accessCount;
    final DateTime lastAccessed;
    final CachePriority priority;
    final int sizeBytes;

    CacheEntry({
      required this.data,
      required this.timestamp,
      required this.expiration,
      this.accessCount = 1,
      DateTime? lastAccessed,
      this.priority = CachePriority.normal,
      int? sizeBytes,
    }) : lastAccessed = lastAccessed ?? DateTime.now(),
         sizeBytes = sizeBytes ?? _estimateSize(data);

    bool get isExpired => DateTime.now().difference(timestamp) > expiration;
    
    CacheEntry copyWithAccess() {
      return CacheEntry(
        data: data,
        timestamp: timestamp,
        expiration: expiration,
        accessCount: accessCount + 1,
        lastAccessed: DateTime.now(),
        priority: priority,
        sizeBytes: sizeBytes,
      );
    }

    static int _estimateSize(dynamic data) {
      try {
        if (data is String) return data.length * 2;
        if (data is Map) return jsonEncode(data).length * 2;
        if (data is List) return jsonEncode(data).length * 2;
        return 100; // Default estimate
      } catch (e) {
        return 100;
      }
    }
  }

  /// Cache priority levels
  enum CachePriority {
    low(1),
    normal(2),
    high(3),
    critical(4);

    const CachePriority(this.value);
    final int value;
  }

  /// Get data from cache with smart fallback
  Future<T?> get<T>(String key, {bool updateAccess = true}) async {
    try {
      // Try memory cache first
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _hits++;
        if (updateAccess) {
          _memoryCache[key] = memoryEntry.copyWithAccess();
        }
        debugPrint('🎯 Memory cache hit for: $key');
        return memoryEntry.data as T?;
      }

      // Try persistent cache
      final persistentData = await _getFromPersistentCache<T>(key);
      if (persistentData != null) {
        _hits++;
        // Promote to memory cache
        await _storeInMemoryCache(key, persistentData, _defaultExpiration);
        debugPrint('💾 Persistent cache hit for: $key');
        return persistentData;
      }

      _misses++;
      debugPrint('❌ Cache miss for: $key');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting from cache: $e');
      _misses++;
      return null;
    }
  }

  /// Store data in cache with smart placement
  Future<void> set(
    String key, 
    dynamic data, {
    Duration? expiration,
    CachePriority priority = CachePriority.normal,
    bool persistToDisk = false,
  }) async {
    try {
      final exp = expiration ?? _getDefaultExpiration(key);
      
      // Always store in memory cache
      await _storeInMemoryCache(key, data, exp, priority);
      
      // Store in persistent cache if requested or if high priority
      if (persistToDisk || priority.value >= CachePriority.high.value) {
        await _storeToPersistentCache(key, data, exp);
      }
      
      debugPrint('💾 Cached: $key (priority: ${priority.name}, persistent: ${persistToDisk || priority.value >= CachePriority.high.value})');
    } catch (e) {
      debugPrint('❌ Error storing in cache: $e');
    }
  }

  /// Store in memory cache with smart eviction
  Future<void> _storeInMemoryCache(
    String key, 
    dynamic data, 
    Duration expiration, [
    CachePriority priority = CachePriority.normal
  ]) async {
    // Clean expired entries first
    _cleanExpiredEntries();
    
    // Check if we need to evict entries
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      await _evictLeastImportant();
    }
    
    _memoryCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiration: expiration,
      priority: priority,
    );
  }

  /// Store in persistent cache
  Future<void> _storeToPersistentCache(String key, dynamic data, Duration expiration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiration': expiration.inMilliseconds,
      };
      
      await prefs.setString('cache_$key', jsonEncode(cacheData));
      
      // Manage persistent cache size
      await _managePersistentCacheSize();
    } catch (e) {
      debugPrint('❌ Error storing to persistent cache: $e');
    }
  }

  /// Get from persistent cache
  Future<T?> _getFromPersistentCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('cache_$key');
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final expiration = Duration(milliseconds: cacheData['expiration']);
      
      if (DateTime.now().difference(timestamp) > expiration) {
        // Remove expired entry
        await prefs.remove('cache_$key');
        return null;
      }
      
      return cacheData['data'] as T?;
    } catch (e) {
      debugPrint('❌ Error getting from persistent cache: $e');
      return null;
    }
  }

  /// Clean expired entries from memory cache
  void _cleanExpiredEntries() {
    final keysToRemove = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('🧹 Cleaned ${keysToRemove.length} expired cache entries');
    }
  }

  /// Evict least important entries using LRU + priority algorithm
  Future<void> _evictLeastImportant() async {
    if (_memoryCache.isEmpty) return;
    
    // Sort by priority (ascending) and last accessed (ascending)
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        // First by priority (lower priority gets evicted first)
        final priorityComparison = a.value.priority.value.compareTo(b.value.priority.value);
        if (priorityComparison != 0) return priorityComparison;
        
        // Then by access count (lower access count gets evicted first)
        final accessComparison = a.value.accessCount.compareTo(b.value.accessCount);
        if (accessComparison != 0) return accessComparison;
        
        // Finally by last accessed time (older gets evicted first)
        return a.value.lastAccessed.compareTo(b.value.lastAccessed);
      });
    
    // Remove 20% of cache or at least 10 entries
    final entriesToRemove = (_memoryCache.length * 0.2).ceil().clamp(10, _memoryCache.length);
    
    for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      _memoryCache.remove(sortedEntries[i].key);
      _evictions++;
    }
    
    debugPrint('🗑️ Evicted $entriesToRemove cache entries');
  }

  /// Manage persistent cache size
  Future<void> _managePersistentCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      if (allKeys.length > _maxPersistentCacheSize) {
        // Remove oldest entries
        final entriesToRemove = allKeys.length - _maxPersistentCacheSize + 50;
        
        for (int i = 0; i < entriesToRemove && i < allKeys.length; i++) {
          await prefs.remove(allKeys[i]);
        }
        
        debugPrint('🧹 Cleaned ${entriesToRemove} persistent cache entries');
      }
    } catch (e) {
      debugPrint('❌ Error managing persistent cache size: $e');
    }
  }

  /// Get default expiration based on key pattern
  Duration _getDefaultExpiration(String key) {
    if (key.startsWith('user_data_') || key.startsWith('student_')) {
      return _defaultExpiration;
    } else if (key.startsWith('bus_') || key.startsWith('route_')) {
      return _longExpiration;
    } else if (key.startsWith('temp_') || key.startsWith('status_')) {
      return _shortExpiration;
    }
    return _defaultExpiration;
  }

  /// Remove specific key from all cache levels
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (e) {
      debugPrint('❌ Error removing from persistent cache: $e');
    }
    
    debugPrint('🗑️ Removed from cache: $key');
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys().where((key) => key.startsWith('cache_'));
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('❌ Error clearing persistent cache: $e');
    }
    
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    
    debugPrint('🗑️ All cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests * 100) : 0.0;
    
    int totalSizeBytes = 0;
    for (final entry in _memoryCache.values) {
      totalSizeBytes += entry.sizeBytes;
    }
    
    return {
      'memoryEntries': _memoryCache.length,
      'maxMemorySize': _maxMemoryCacheSize,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hitRate': hitRate.toStringAsFixed(2),
      'totalSizeKB': (totalSizeBytes / 1024).toStringAsFixed(2),
      'averageAccessCount': _memoryCache.values.isEmpty 
          ? 0.0 
          : _memoryCache.values.map((e) => e.accessCount).reduce((a, b) => a + b) / _memoryCache.length,
    };
  }

  /// Preload frequently accessed data
  Future<void> preloadData(Map<String, dynamic> dataMap) async {
    for (final entry in dataMap.entries) {
      await set(
        entry.key, 
        entry.value, 
        priority: CachePriority.high,
        persistToDisk: true,
      );
    }
    debugPrint('📦 Preloaded ${dataMap.length} cache entries');
  }
}
