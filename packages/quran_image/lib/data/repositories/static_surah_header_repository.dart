import '../../core/constants/surah_header_constants.dart';
import '../../domain/domain.dart';

/// Static implementation of the [SurahHeaderRepository].
///
/// Uses a pre-compiled page-to-header map so page lookups are O(1).
class StaticSurahHeaderRepository implements SurahHeaderRepository {
  const StaticSurahHeaderRepository();

  @override
  List<SurahHeaderData> getHeadersForPage(int pageNumber) {
    return _pageHeaders[pageNumber] ?? const <SurahHeaderData>[];
  }

  // Pre-compiled combination of the page/line mapping and ink-center fractions.
  static const Map<int, List<SurahHeaderData>> _pageHeaders = {
    1: [
      SurahHeaderData(
        pageNumber: 1,
        lineIndex: 3,
        inkCenterYFraction: SurahHeaderConstants.defaultInkCenterYFraction,
      ),
    ],
    2: [
      SurahHeaderData(pageNumber: 2, lineIndex: 3, inkCenterYFraction: 0.5022),
    ],
    50: [
      SurahHeaderData(pageNumber: 50, lineIndex: 0, inkCenterYFraction: 0.4526),
    ],
    77: [
      SurahHeaderData(pageNumber: 77, lineIndex: 0, inkCenterYFraction: 0.4806),
    ],
    106: [
      SurahHeaderData(
        pageNumber: 106,
        lineIndex: 5,
        inkCenterYFraction: 0.5302,
      ),
    ],
    128: [
      SurahHeaderData(
        pageNumber: 128,
        lineIndex: 0,
        inkCenterYFraction: 0.4504,
      ),
    ],
    151: [
      SurahHeaderData(
        pageNumber: 151,
        lineIndex: 0,
        inkCenterYFraction: 0.4461,
      ),
    ],
    177: [
      SurahHeaderData(
        pageNumber: 177,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    187: [
      SurahHeaderData(
        pageNumber: 187,
        lineIndex: 0,
        inkCenterYFraction: 0.4720,
      ),
    ],
    208: [
      SurahHeaderData(
        pageNumber: 208,
        lineIndex: 0,
        inkCenterYFraction: 0.4569,
      ),
    ],
    221: [
      SurahHeaderData(
        pageNumber: 221,
        lineIndex: 6,
        inkCenterYFraction: 0.4698,
      ),
    ],
    235: [
      SurahHeaderData(
        pageNumber: 235,
        lineIndex: 8,
        inkCenterYFraction: 0.5560,
      ),
    ],
    249: [
      SurahHeaderData(
        pageNumber: 249,
        lineIndex: 0,
        inkCenterYFraction: 0.4720,
      ),
    ],
    255: [
      SurahHeaderData(
        pageNumber: 255,
        lineIndex: 2,
        inkCenterYFraction: 0.4914,
      ),
    ],
    262: [
      SurahHeaderData(
        pageNumber: 262,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    267: [
      SurahHeaderData(
        pageNumber: 267,
        lineIndex: 6,
        inkCenterYFraction: 0.5043,
      ),
    ],
    282: [
      SurahHeaderData(
        pageNumber: 282,
        lineIndex: 0,
        inkCenterYFraction: 0.4698,
      ),
    ],
    293: [
      SurahHeaderData(
        pageNumber: 293,
        lineIndex: 9,
        inkCenterYFraction: 0.6099,
      ),
    ],
    305: [
      SurahHeaderData(
        pageNumber: 305,
        lineIndex: 0,
        inkCenterYFraction: 0.4569,
      ),
    ],
    312: [
      SurahHeaderData(
        pageNumber: 312,
        lineIndex: 4,
        inkCenterYFraction: 0.4957,
      ),
    ],
    322: [
      SurahHeaderData(
        pageNumber: 322,
        lineIndex: 0,
        inkCenterYFraction: 0.4591,
      ),
    ],
    332: [
      SurahHeaderData(
        pageNumber: 332,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    342: [
      SurahHeaderData(
        pageNumber: 342,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    350: [
      SurahHeaderData(
        pageNumber: 350,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    359: [
      SurahHeaderData(
        pageNumber: 359,
        lineIndex: 10,
        inkCenterYFraction: 0.5711,
      ),
    ],
    367: [
      SurahHeaderData(
        pageNumber: 367,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    377: [
      SurahHeaderData(
        pageNumber: 377,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    385: [
      SurahHeaderData(
        pageNumber: 385,
        lineIndex: 7,
        inkCenterYFraction: 0.5539,
      ),
    ],
    396: [
      SurahHeaderData(
        pageNumber: 396,
        lineIndex: 7,
        inkCenterYFraction: 0.5237,
      ),
    ],
    404: [
      SurahHeaderData(
        pageNumber: 404,
        lineIndex: 9,
        inkCenterYFraction: 0.6250,
      ),
    ],
    411: [
      SurahHeaderData(
        pageNumber: 411,
        lineIndex: 0,
        inkCenterYFraction: 0.4504,
      ),
    ],
    415: [
      SurahHeaderData(
        pageNumber: 415,
        lineIndex: 0,
        inkCenterYFraction: 0.4591,
      ),
    ],
    418: [
      SurahHeaderData(
        pageNumber: 418,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    428: [
      SurahHeaderData(
        pageNumber: 428,
        lineIndex: 0,
        inkCenterYFraction: 0.4741,
      ),
    ],
    434: [
      SurahHeaderData(
        pageNumber: 434,
        lineIndex: 7,
        inkCenterYFraction: 0.5841,
      ),
    ],
    440: [
      SurahHeaderData(
        pageNumber: 440,
        lineIndex: 3,
        inkCenterYFraction: 0.4741,
      ),
    ],
    446: [
      SurahHeaderData(
        pageNumber: 446,
        lineIndex: 0,
        inkCenterYFraction: 0.4677,
      ),
    ],
    453: [
      SurahHeaderData(
        pageNumber: 453,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    458: [
      SurahHeaderData(
        pageNumber: 458,
        lineIndex: 3,
        inkCenterYFraction: 0.5280,
      ),
    ],
    467: [
      SurahHeaderData(
        pageNumber: 467,
        lineIndex: 2,
        inkCenterYFraction: 0.5453,
      ),
    ],
    477: [
      SurahHeaderData(
        pageNumber: 477,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    483: [
      SurahHeaderData(
        pageNumber: 483,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    489: [
      SurahHeaderData(
        pageNumber: 489,
        lineIndex: 4,
        inkCenterYFraction: 0.5948,
      ),
    ],
    496: [
      SurahHeaderData(
        pageNumber: 496,
        lineIndex: 0,
        inkCenterYFraction: 0.4677,
      ),
    ],
    499: [
      SurahHeaderData(
        pageNumber: 499,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    502: [
      SurahHeaderData(
        pageNumber: 502,
        lineIndex: 6,
        inkCenterYFraction: 0.5323,
      ),
    ],
    507: [
      SurahHeaderData(
        pageNumber: 507,
        lineIndex: 0,
        inkCenterYFraction: 0.4741,
      ),
    ],
    511: [
      SurahHeaderData(
        pageNumber: 511,
        lineIndex: 0,
        inkCenterYFraction: 0.4763,
      ),
    ],
    515: [
      SurahHeaderData(
        pageNumber: 515,
        lineIndex: 6,
        inkCenterYFraction: 0.5841,
      ),
    ],
    518: [
      SurahHeaderData(
        pageNumber: 518,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    520: [
      SurahHeaderData(
        pageNumber: 520,
        lineIndex: 11,
        inkCenterYFraction: 0.5927,
      ),
    ],
    523: [
      SurahHeaderData(
        pageNumber: 523,
        lineIndex: 7,
        inkCenterYFraction: 0.5129,
      ),
    ],
    526: [
      SurahHeaderData(
        pageNumber: 526,
        lineIndex: 0,
        inkCenterYFraction: 0.4677,
      ),
    ],
    528: [
      SurahHeaderData(
        pageNumber: 528,
        lineIndex: 9,
        inkCenterYFraction: 0.5043,
      ),
    ],
    531: [
      SurahHeaderData(
        pageNumber: 531,
        lineIndex: 4,
        inkCenterYFraction: 0.5690,
      ),
    ],
    534: [
      SurahHeaderData(
        pageNumber: 534,
        lineIndex: 6,
        inkCenterYFraction: 0.5151,
      ),
    ],
    537: [
      SurahHeaderData(
        pageNumber: 537,
        lineIndex: 10,
        inkCenterYFraction: 0.5991,
      ),
    ],
    542: [
      SurahHeaderData(
        pageNumber: 542,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    545: [
      SurahHeaderData(
        pageNumber: 545,
        lineIndex: 6,
        inkCenterYFraction: 0.5172,
      ),
    ],
    549: [
      SurahHeaderData(
        pageNumber: 549,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    551: [
      SurahHeaderData(
        pageNumber: 551,
        lineIndex: 6,
        inkCenterYFraction: 0.5474,
      ),
    ],
    553: [
      SurahHeaderData(
        pageNumber: 553,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
    ],
    554: [
      SurahHeaderData(
        pageNumber: 554,
        lineIndex: 6,
        inkCenterYFraction: 0.5517,
      ),
    ],
    556: [
      SurahHeaderData(
        pageNumber: 556,
        lineIndex: 0,
        inkCenterYFraction: 0.4720,
      ),
    ],
    558: [
      SurahHeaderData(
        pageNumber: 558,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    560: [
      SurahHeaderData(
        pageNumber: 560,
        lineIndex: 0,
        inkCenterYFraction: 0.4698,
      ),
    ],
    562: [
      SurahHeaderData(
        pageNumber: 562,
        lineIndex: 0,
        inkCenterYFraction: 0.4547,
      ),
    ],
    564: [
      SurahHeaderData(
        pageNumber: 564,
        lineIndex: 5,
        inkCenterYFraction: 0.5948,
      ),
    ],
    566: [
      SurahHeaderData(
        pageNumber: 566,
        lineIndex: 9,
        inkCenterYFraction: 0.5517,
      ),
    ],
    568: [
      SurahHeaderData(
        pageNumber: 568,
        lineIndex: 8,
        inkCenterYFraction: 0.5991,
      ),
    ],
    570: [
      SurahHeaderData(
        pageNumber: 570,
        lineIndex: 4,
        inkCenterYFraction: 0.5237,
      ),
    ],
    572: [
      SurahHeaderData(
        pageNumber: 572,
        lineIndex: 0,
        inkCenterYFraction: 0.4698,
      ),
    ],
    574: [
      SurahHeaderData(
        pageNumber: 574,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
    ],
    575: [
      SurahHeaderData(
        pageNumber: 575,
        lineIndex: 7,
        inkCenterYFraction: 0.5302,
      ),
    ],
    577: [
      SurahHeaderData(
        pageNumber: 577,
        lineIndex: 5,
        inkCenterYFraction: 0.4634,
      ),
    ],
    578: [
      SurahHeaderData(
        pageNumber: 578,
        lineIndex: 9,
        inkCenterYFraction: 0.5302,
      ),
    ],
    580: [
      SurahHeaderData(
        pageNumber: 580,
        lineIndex: 6,
        inkCenterYFraction: 0.5237,
      ),
    ],
    582: [
      SurahHeaderData(
        pageNumber: 582,
        lineIndex: 0,
        inkCenterYFraction: 0.4763,
      ),
    ],
    583: [
      SurahHeaderData(
        pageNumber: 583,
        lineIndex: 7,
        inkCenterYFraction: 0.5582,
      ),
    ],
    585: [
      SurahHeaderData(
        pageNumber: 585,
        lineIndex: 0,
        inkCenterYFraction: 0.4612,
      ),
    ],
    586: [
      SurahHeaderData(
        pageNumber: 586,
        lineIndex: 1,
        inkCenterYFraction: 0.5259,
      ),
    ],
    587: [
      SurahHeaderData(
        pageNumber: 587,
        lineIndex: 0,
        inkCenterYFraction: 0.4698,
      ),
      SurahHeaderData(
        pageNumber: 587,
        lineIndex: 11,
        inkCenterYFraction: 0.5690,
      ),
    ],
    589: [
      SurahHeaderData(
        pageNumber: 589,
        lineIndex: 2,
        inkCenterYFraction: 0.5172,
      ),
    ],
    590: [
      SurahHeaderData(
        pageNumber: 590,
        lineIndex: 1,
        inkCenterYFraction: 0.5366,
      ),
    ],
    591: [
      SurahHeaderData(
        pageNumber: 591,
        lineIndex: 0,
        inkCenterYFraction: 0.4655,
      ),
      SurahHeaderData(
        pageNumber: 591,
        lineIndex: 9,
        inkCenterYFraction: 0.5474,
      ),
    ],
    592: [
      SurahHeaderData(
        pageNumber: 592,
        lineIndex: 4,
        inkCenterYFraction: 0.4978,
      ),
    ],
    593: [
      SurahHeaderData(
        pageNumber: 593,
        lineIndex: 2,
        inkCenterYFraction: 0.4978,
      ),
    ],
    594: [
      SurahHeaderData(
        pageNumber: 594,
        lineIndex: 5,
        inkCenterYFraction: 0.5560,
      ),
    ],
    595: [
      SurahHeaderData(
        pageNumber: 595,
        lineIndex: 1,
        inkCenterYFraction: 0.5216,
      ),
      SurahHeaderData(
        pageNumber: 595,
        lineIndex: 10,
        inkCenterYFraction: 0.5690,
      ),
    ],
    596: [
      SurahHeaderData(
        pageNumber: 596,
        lineIndex: 5,
        inkCenterYFraction: 0.5000,
      ),
      SurahHeaderData(
        pageNumber: 596,
        lineIndex: 12,
        inkCenterYFraction: 0.5151,
      ),
    ],
    597: [
      SurahHeaderData(
        pageNumber: 597,
        lineIndex: 2,
        inkCenterYFraction: 0.5496,
      ),
      SurahHeaderData(
        pageNumber: 597,
        lineIndex: 8,
        inkCenterYFraction: 0.5366,
      ),
    ],
    598: [
      SurahHeaderData(
        pageNumber: 598,
        lineIndex: 3,
        inkCenterYFraction: 0.5302,
      ),
      SurahHeaderData(
        pageNumber: 598,
        lineIndex: 8,
        inkCenterYFraction: 0.6142,
      ),
    ],
    599: [
      SurahHeaderData(
        pageNumber: 599,
        lineIndex: 5,
        inkCenterYFraction: 0.5409,
      ),
      SurahHeaderData(
        pageNumber: 599,
        lineIndex: 11,
        inkCenterYFraction: 0.5733,
      ),
    ],
    600: [
      SurahHeaderData(
        pageNumber: 600,
        lineIndex: 3,
        inkCenterYFraction: 0.5043,
      ),
      SurahHeaderData(
        pageNumber: 600,
        lineIndex: 10,
        inkCenterYFraction: 0.4935,
      ),
    ],
    601: [
      SurahHeaderData(
        pageNumber: 601,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
      SurahHeaderData(
        pageNumber: 601,
        lineIndex: 4,
        inkCenterYFraction: 0.5280,
      ),
      SurahHeaderData(
        pageNumber: 601,
        lineIndex: 10,
        inkCenterYFraction: 0.6013,
      ),
    ],
    602: [
      SurahHeaderData(
        pageNumber: 602,
        lineIndex: 0,
        inkCenterYFraction: 0.4634,
      ),
      SurahHeaderData(
        pageNumber: 602,
        lineIndex: 5,
        inkCenterYFraction: 0.5884,
      ),
      SurahHeaderData(
        pageNumber: 602,
        lineIndex: 11,
        inkCenterYFraction: 0.5690,
      ),
    ],
    603: [
      SurahHeaderData(
        pageNumber: 603,
        lineIndex: 0,
        inkCenterYFraction: 0.4461,
      ),
      SurahHeaderData(
        pageNumber: 603,
        lineIndex: 5,
        inkCenterYFraction: 0.5431,
      ),
      SurahHeaderData(
        pageNumber: 603,
        lineIndex: 10,
        inkCenterYFraction: 0.5690,
      ),
    ],
    604: [
      SurahHeaderData(
        pageNumber: 604,
        lineIndex: 0,
        inkCenterYFraction: 0.4483,
      ),
      SurahHeaderData(
        pageNumber: 604,
        lineIndex: 4,
        inkCenterYFraction: 0.5237,
      ),
      SurahHeaderData(
        pageNumber: 604,
        lineIndex: 9,
        inkCenterYFraction: 0.5862,
      ),
    ],
  };
}
