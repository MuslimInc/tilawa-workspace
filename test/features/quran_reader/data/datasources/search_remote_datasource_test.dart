import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/data/datasources/search_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SearchRemoteDataSource dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = SearchRemoteDataSource(mockDio);
  });

  group('SearchRemoteDataSource', () {
    const tQuery = 'test';
    final Map<String, List<Map<String, Object>>> tResponseData = {
      'results': [
        {
          'verse_key': '2:183',
          'translations': [
            {'text': 'O you who have <em>believed</em>...'},
          ],
        },
      ],
    };

    test('should return list of RemoteSearchResult on success', () async {
      // Arrange
      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          data: tResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final List<RemoteSearchResult> result = await dataSource.search(tQuery);

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.verseKey, '2:183');
      expect(result.first.translation, contains('<em>believed</em>'));
    });

    test('should return empty list on error', () async {
      // Arrange
      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      // Act
      final List<RemoteSearchResult> result = await dataSource.search(tQuery);

      // Assert
      expect(result, isEmpty);
    });
  });
}
