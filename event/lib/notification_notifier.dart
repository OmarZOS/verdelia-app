import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:event/TraceableNotifier.dart';
import 'package:flutter/material.dart';
import 'package:locator/locator.dart';

import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:verdelia_core/app/Notifications/NotificationContent.dart';
import 'package:verdelia_core/app/Notifications/NotificationList.dart';
import 'package:verdelia_core/app/Services/NotificationService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';

// ============ CACHE ENTRY WITH TTL ============
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final int ttlSeconds;

  _CacheEntry(this.data, {this.ttlSeconds = 300}) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds > ttlSeconds;
  bool get isValid => !isExpired;
}

// ============ NOTIFICATION CHANGE NOTIFIER ============
class NotificationNotifier extends TraceableNotifier {
  final NotificationService _notificationService =
      AppLocator.get<NotificationService>();

  // ============ CACHE STORAGE ============
  final Map<int, VerdeliaNotification> _notificationCache = {};
  final Map<String, _CacheEntry<NotificationList>> _listCache = {};

  // LRU cache for frequently accessed notifications
  final LinkedHashMap<int, _CacheEntry<VerdeliaNotification>> _lruCache =
      LinkedHashMap();

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // Cache configuration
  static const int _maxCacheSize = 200;
  static const int _defaultCacheTTLSeconds = 300; // 5 minutes
  static const int _shortCacheTTLSeconds = 60; // 1 minute
  static const int _longCacheTTLSeconds = 3600; // 1 hour

  // Pagination constants
  static const int _itemsPerPage = 20;
  static const int _maxPageSize = 100;

  // Pagination state
  int _currentPage = 0;
  int _totalCount = 0;
  bool _hasMore = true;
  int _currentUserId = 0;
  bool _showOnlyUnread = false;

  // State management
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;

  // Batch request debouncing
  final Map<String, Future<NotificationList>> _pendingRequests = {};

  // Notification list cache keys
  String _getListCacheKey(int userId, int page, int limit, bool unreadOnly) {
    return 'notifications_${userId}_${page}_${limit}_${unreadOnly}';
  }

  NotificationNotifier();

  // ============ LIFECYCLE ============

  @override
  void dispose() {
    _isDisposed = true;
    _clearAllCaches();
    _pendingRequests.clear();
    super.dispose();
  }

  // ============ CACHE MANAGEMENT ============

  void _clearAllCaches() {
    _notificationCache.clear();
    _lruCache.clear();
    _listCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  void _invalidateCache({int? notificationId, String? listKey}) {
    if (notificationId != null) {
      _notificationCache.remove(notificationId);
      _lruCache.remove(notificationId);
    }

    if (listKey != null) {
      _listCache.remove(listKey);
    }

    if (notificationId == null && listKey == null) {
      _clearAllCaches();
    }
  }

  void _addToLRUCache(int id, VerdeliaNotification notification) {
    if (_lruCache.containsKey(id)) {
      _lruCache.remove(id);
    }

    while (_lruCache.length >= _maxCacheSize) {
      final oldestKey = _lruCache.keys.first;
      _lruCache.remove(oldestKey);
    }

    _lruCache[id] =
        _CacheEntry(notification, ttlSeconds: _defaultCacheTTLSeconds);
  }

  VerdeliaNotification? _getFromLRUCache(int id) {
    final entry = _lruCache[id];
    if (entry == null) return null;

    if (entry.isExpired) {
      _lruCache.remove(id);
      _cacheMisses++;
      return null;
    }

    _lruCache.remove(id);
    _lruCache[id] = entry;

    _cacheHits++;
    return entry.data;
  }

  void _cacheList(String key, NotificationList list, {int? ttlSeconds}) {
    _listCache[key] =
        _CacheEntry(list, ttlSeconds: ttlSeconds ?? _defaultCacheTTLSeconds);

    // Cache individual notifications
    for (final notification in list.notifications) {
      _cacheNotification(notification);
    }
  }

  NotificationList? _getFromListCache(String key) {
    final entry = _listCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _listCache.remove(key);
      _cacheMisses++;
      return null;
    }

    _cacheHits++;
    return entry.data;
  }

  void _cacheNotification(VerdeliaNotification notification, {int? ttlSeconds}) {
    final ttl = ttlSeconds ?? _defaultCacheTTLSeconds;
    _notificationCache[notification.idNotification] = notification;
    _addToLRUCache(notification.idNotification, notification);
  }

  VerdeliaNotification? _getCachedNotification(int id) {
    final lruCached = _getFromLRUCache(id);
    if (lruCached != null) return lruCached;

    final cached = _notificationCache[id];
    if (cached != null) {
      _addToLRUCache(id, cached);
      _cacheHits++;
      return cached;
    }

    _cacheMisses++;
    return null;
  }

  // ============ SAFE NOTIFICATION ============

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      _safeNotifyListeners();
    }
  }

  // ============ PUBLIC GETTERS ============

  NotificationList get notifications => _notificationList;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;
  String? get error => _error;
  int get unreadCount => _notificationList.unreadCount;
  int get pendingActionCount => _notificationList.pendingActionCount;

  NotificationList _notificationList = NotificationList(notifications: []);

  // ============ CACHE CONFIGURATION ============

  void invalidateCache({int? notificationId, String? listKey}) {
    _invalidateCache(notificationId: notificationId, listKey: listKey);
    _safeNotifyListeners();
  }

  void refreshAllCaches() {
    _clearAllCaches();
    _safeNotifyListeners();
  }

  // ============ NOTIFICATION FETCHING ============

  Future<void> loadInitialNotifications(
    int userId, {
    int limit = 20,
    bool unreadOnly = false,
    bool forceRefresh = false,
  }) async {
    final operationKey = getCallerKey('loadInitialNotifications',
        suffix: '${userId}_${limit}_${unreadOnly}');

    // Check cache
    if (!forceRefresh) {
      final cacheKey = _getListCacheKey(userId, 0, limit, unreadOnly);
      final cached = _getFromListCache(cacheKey);
      if (cached != null && cached.notifications.isNotEmpty) {
        _notificationList = cached;
        _currentPage = 1;
        _currentUserId = userId;
        _showOnlyUnread = unreadOnly;
        _totalCount = cached.totalCount;
        _hasMore = cached.notifications.length < cached.totalCount;
        storeSuccess(operationKey, cached, responseCode: 'CACHE_HIT');
        _safeNotifyListeners();
        return;
      }
    }

    if (_isLoading) {
      storeFailure(operationKey, null,
          errorCode: 'LOADING', message: 'Already loading');
      return;
    }

    _setLoading(true);
    _setError(null);
    _currentUserId = userId;
    _showOnlyUnread = unreadOnly;
    _currentPage = 0;

    try {
      final response = await _notificationService.getNotificationsByUserId(
        userId,
        page: 0,
        limit: limit,
        callerKey: operationKey,
      );

      final statusCode = getStatusCode(operationKey);
      final responseCode = getResponseCode(operationKey);

      // Cache the result
      final cacheKey = _getListCacheKey(userId, 0, limit, unreadOnly);
      _cacheList(cacheKey, response, ttlSeconds: _shortCacheTTLSeconds);

      _notificationList = response;
      _currentPage = 1;
      _totalCount = response.totalCount;
      _hasMore = response.notifications.length < response.totalCount;

      storeSuccess(operationKey, response,
          code: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
      logInfo(
          'Loaded ${response.notifications.length} notifications for user $userId');
    } catch (e, stackTrace) {
      _setError('Failed to load notifications: $e');
      logError('Error loading notifications', error: e, stackTrace: stackTrace);
      storeFailure(operationKey, e.toString(),
          errorCode: 'LOAD_ERROR', message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreNotifications({int limit = 20}) async {
    if (_isLoading || !_hasMore) return;

    final operationKey = getCallerKey('loadMoreNotifications',
        suffix: '${_currentUserId}_${_currentPage}_${limit}');

    // Check cache for next page
    final cacheKey =
        _getListCacheKey(_currentUserId, _currentPage, limit, _showOnlyUnread);
    final cached = _getFromListCache(cacheKey);
    if (cached != null && cached.notifications.isNotEmpty) {
      final allNotifications = [
        ..._notificationList.notifications,
        ...cached.notifications,
      ];
      _notificationList = NotificationList(
        notifications: allNotifications,
        totalCount: cached.totalCount,
        unreadCount: allNotifications.where((n) => !n.isRead).length,
      );
      _currentPage++;
      _hasMore =
          _notificationList.notifications.length < _notificationList.totalCount;
      storeSuccess(operationKey, cached, responseCode: 'CACHE_HIT');
      _safeNotifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final response = await _notificationService.getNotificationsByUserId(
        _currentUserId,
        page: _currentPage,
        limit: limit,
        callerKey: operationKey,
      );

      final statusCode = getStatusCode(operationKey);
      final responseCode = getResponseCode(operationKey);

      // Cache the result
      _cacheList(cacheKey, response, ttlSeconds: _shortCacheTTLSeconds);

      final allNotifications = [
        ..._notificationList.notifications,
        ...response.notifications,
      ];

      _notificationList = NotificationList(
        notifications: allNotifications,
        totalCount: response.totalCount,
        unreadCount: allNotifications.where((n) => !n.isRead).length,
      );
      _currentPage++;
      _hasMore =
          _notificationList.notifications.length < _notificationList.totalCount;

      storeSuccess(operationKey, response,
          code: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
      logInfo('Loaded ${response.notifications.length} more notifications');
    } catch (e) {
      _setError('Failed to load more notifications: $e');
      logError('Error loading more notifications', error: e);
      storeFailure(operationKey, e.toString(),
          errorCode: 'LOAD_MORE_ERROR', message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshNotifications(int userId,
      {int limit = 20, bool unreadOnly = false}) async {
    // Invalidate cache before refresh
    final cacheKey = _getListCacheKey(userId, 0, limit, unreadOnly);
    _invalidateCache(listKey: cacheKey);
    await loadInitialNotifications(userId,
        limit: limit, unreadOnly: unreadOnly, forceRefresh: true);
  }

  // ============ NOTIFICATION ACTIONS ============

  Future<void> markAsRead(int notificationId, {String? callerKey}) async {
    final operationKey =
        callerKey ?? getCallerKey('markAsRead', id: notificationId.toString());

    if (_isLoading) {
      storeFailure(operationKey, null,
          errorCode: 'LOADING', message: 'Already loading');
      return;
    }

    _setLoading(true);

    try {
      await _notificationService.markAsRead(notificationId,
          callerKey: operationKey);

      final statusCode = getStatusCode(operationKey);
      final responseCode = getResponseCode(operationKey);

      // Update local state
      _notificationList = _notificationList.markAsRead(notificationId);
      _invalidateCache(notificationId: notificationId);

      storeSuccess(operationKey, true,
          code: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
      logInfo('Marked notification $notificationId as read');
    } catch (e) {
      logError('Error marking notification as read', error: e);
      _setError('Failed to mark notification as read: $e');
      storeFailure(operationKey, e.toString(),
          errorCode: 'MARK_READ_ERROR', message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAllAsRead({String? callerKey}) async {
    final operationKey = callerKey ??
        getCallerKey('markAllAsRead', id: _currentUserId.toString());

    if (_isLoading) {
      storeFailure(operationKey, null,
          errorCode: 'LOADING', message: 'Already loading');
      return;
    }

    _setLoading(true);

    try {
      await _notificationService.markAllAsRead(_currentUserId,
          callerKey: operationKey);

      final statusCode = getStatusCode(operationKey);
      final responseCode = getResponseCode(operationKey);

      // Update local state
      _notificationList = _notificationList.markAllAsRead();

      storeSuccess(operationKey, true,
          code: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
      logInfo('Marked all notifications as read for user $_currentUserId');
    } catch (e) {
      logError('Error marking all notifications as read', error: e);
      _setError('Failed to mark all notifications as read: $e');
      storeFailure(operationKey, e.toString(),
          errorCode: 'MARK_ALL_READ_ERROR', message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNotification(int notificationId,
      {String? callerKey}) async {
    final operationKey = callerKey ??
        getCallerKey('deleteNotification', id: notificationId.toString());

    if (_isLoading) {
      storeFailure(operationKey, null,
          errorCode: 'LOADING', message: 'Already loading');
      return;
    }

    _setLoading(true);

    try {
      final success = await _notificationService.deleteNotification(
        notificationId,
        callerKey: operationKey,
      );

      final statusCode = getStatusCode(operationKey);
      final responseCode = getResponseCode(operationKey);

      if (statusCode == 200 || statusCode == 201) {
        // Update local state
        _notificationList =
            _notificationList.removeNotification(notificationId);
        _invalidateCache(notificationId: notificationId);
        _totalCount--;

        storeSuccess(operationKey, true,
            code: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
        logInfo('Deleted notification $notificationId');
      } else {
        storeFailure(operationKey, false,
            errorCode: 'DELETE_FAILED',
            message: 'Failed to delete notification');
      }
    } catch (e) {
      logError('Error deleting notification', error: e);
      _setError('Failed to delete notification: $e');
      storeFailure(operationKey, e.toString(),
          errorCode: 'DELETE_ERROR', message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ============ HELPER METHODS ============

  void clearError() {
    _setError(null);
  }

  VerdeliaNotification? getNotificationById(int id) {
    return _getCachedNotification(id) ??
        _notificationList.getNotificationById(id);
  }

  // ============ FILTER METHODS ============

  List<VerdeliaNotification> get unreadNotifications =>
      _notificationList.unreadNotifications;

  List<VerdeliaNotification> get readNotifications =>
      _notificationList.readNotifications;

  List<VerdeliaNotification> get requiresActionNotifications =>
      _notificationList.requiresActionNotifications;

  List<VerdeliaNotification> get sortedByDate => _notificationList.sortedByDate;

  List<VerdeliaNotification> getRoleInvitations() =>
      _notificationList.getRoleInvitations();

  List<VerdeliaNotification> getByContentType<T extends NotificationContent>() =>
      _notificationList.getByContentType<T>();

  // ============ STATE RESET ============

  void reset() {
    _clearAllCaches();
    _notificationList = NotificationList(notifications: []);
    _currentPage = 0;
    _totalCount = 0;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    _currentUserId = 0;
    _showOnlyUnread = false;
    _pendingRequests.clear();

    _safeNotifyListeners();
  }
}
