import 'dart:async';

import 'package:dio/dio.dart';

import '../models/puzzle.dart';

/// Custom exception for API errors with user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

/// Service to interact with the public Lichess API.
/// Meets requirements §3.7 and error handling in §3.7.1.
class LichessApi {
  final Dio _dio;
  final String endpoint;
  static const String dailyPuzzleEndpoint =
      'https://lichess.org/api/puzzle/daily';

  DailyPuzzle? _cachedDailyPuzzle;

  LichessApi({Dio? dio, String? endpoint})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'Accept': 'application/json'},
            ),
          ),
      endpoint = endpoint ?? dailyPuzzleEndpoint;

  /// Returns the cached puzzle if available from this session.
  DailyPuzzle? get cachedDailyPuzzle => _cachedDailyPuzzle;

  /// Fetches the current daily puzzle from Lichess.
  /// Implements retry with exponential backoff on timeouts/5xx, handles 429,
  /// and falls back to cached puzzle on network loss.
  Future<DailyPuzzle> dailyPuzzle() async {
    const maxRetries = 2;
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        final response = await _dio.get<Map<String, dynamic>>(endpoint);

        if (response.statusCode == 200 && response.data != null) {
          final puzzle = DailyPuzzle.fromJson(response.data!);
          _cachedDailyPuzzle = puzzle;
          return puzzle;
        }

        throw ApiException(
          'Invalid response from server',
          statusCode: response.statusCode,
        );
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // 429 Rate limited -> wait and retry once
        if (statusCode == 429 && attempt <= 2) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        // Timeout or 5xx server error -> retry up to 2 times with exponential backoff
        final isTimeout =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        final isServerError =
            statusCode != null && statusCode >= 500 && statusCode < 600;

        if ((isTimeout || isServerError) && attempt <= maxRetries) {
          final backoffMs = 1000 * (1 << (attempt - 1)); // 1s, 2s
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        // No connectivity or connection error
        final isConnectionError = e.type == DioExceptionType.connectionError;
        if (isConnectionError) {
          if (_cachedDailyPuzzle != null) {
            return _cachedDailyPuzzle!;
          }
          throw const ApiException(
            'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อของคุณ',
            isNetworkError: true,
          );
        }

        if (statusCode != null) {
          throw ApiException(
            'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ ($statusCode)',
            statusCode: statusCode,
          );
        }

        throw ApiException(
          _cachedDailyPuzzle != null
              ? 'ไม่สามารถโหลดพัซเซิลใหม่ได้ กำลังใช้ข้อมูลที่บันทึกไว้'
              : 'เกิดข้อผิดพลาดในการโหลดพัซเซิลประจำวัน',
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('ไม่สามารถประมวลผลข้อมูลพัซเซิลได้: $e');
      }
    }
  }
}
