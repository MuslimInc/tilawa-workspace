package com.tilawa.quran.kmp

/**
 * Represents a single word in the Quran.
 */
data class QuranWord(
    val text: String,
    val page: Int,
    val line: Int,
    val audioUrl: String? = null
)

/**
 * Represents a line of text on a Quran page.
 */
data class QuranLine(
    val lineNumber: Int,
    val words: List<QuranWord>
)

/**
 * Represents a full page of the Quran (standard 15 lines).
 */
data class QuranPage(
    val pageNumber: Int,
    val lines: List<QuranLine>,
    val juzNumber: Int = 0,
    val surahName: String = ""
)
