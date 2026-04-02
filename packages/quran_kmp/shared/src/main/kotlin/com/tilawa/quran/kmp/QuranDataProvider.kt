package com.tilawa.quran.kmp

import android.content.res.AssetManager
import android.util.JsonReader
import java.io.InputStreamReader

/**
 * Loads Quran page data from assets.
 * Optimized for Android memory constraints.
 */
class QuranDataProvider(private val assetManager: AssetManager) {

    private val pageData = mutableMapOf<Int, MutableMap<Int, MutableList<QuranWord>>>()
    private val pageJuz = mutableMapOf<Int, Int>()
    private val pageSurah = mutableMapOf<Int, Int>()
    // Fully-built QuranPage objects, constructed once and reused on every getPage call.
    private val pageCache = mutableMapOf<Int, QuranPage>()

    init {
        loadData()
        loadMetadata()
        buildPageCache()
    }

    private fun loadData() {
        val wordTexts = mutableMapOf<String, String>()

        // 1. Reading qpc-v4.json (approx. 7.8MB)
        assetManager.open("data/qpc-v4.json").use { inputStream ->
            val reader = JsonReader(InputStreamReader(inputStream, "UTF-8"))
            reader.beginObject()
                while (reader.hasNext()) {
                    val key = reader.nextName()
                    reader.beginObject()
                    while (reader.hasNext()) {
                        if (reader.nextName() == "text") {
                            // Store raw text first. Mapping happens later when we know the page.
                            wordTexts[key] = reader.nextString()
                        } else {
                            reader.skipValue()
                        }
                    }
                    reader.endObject()
                }
            reader.endObject()
        }

        // 2. Reading quran_page_line_map.json (approx. 2.2MB)
        assetManager.open("data/quran_page_line_map.json").use { inputStream ->
            val reader = JsonReader(InputStreamReader(inputStream, "UTF-8"))
            reader.beginObject()
            while (reader.hasNext()) {
                val key = reader.nextName()
                var p = -1
                var l = -1
                reader.beginObject()
                while (reader.hasNext()) {
                    when (reader.nextName()) {
                        "p" -> p = reader.nextInt()
                        "l" -> l = reader.nextInt()
                        else -> reader.skipValue()
                    }
                }
                reader.endObject()

                if (p != -1 && l != -1) {
                    val rawText = wordTexts[key] ?: ""
                    val word = QuranWord(rawText, p, l)
                    
                    val lines = pageData.getOrPut(p) { mutableMapOf() }
                    val wordsInLine = lines.getOrPut(l) { mutableListOf() }
                    wordsInLine.add(word)

                    // Extract Surah Number from key (surah:aya:word)
                    val surahNum = key.split(":")[0].toIntOrNull() ?: 1
                    if (!pageSurah.containsKey(p)) {
                        pageSurah[p] = surahNum
                    }
                }
            }
            reader.endObject()
        }
        
        wordTexts.clear()
    }

    private fun loadMetadata() {
        // Juz-to-Page mapping (approximate standard Madani Mushaf)
        val juzStarts = listOf(
            1, 22, 42, 62, 82, 102, 122, 142, 162, 182,
            202, 222, 242, 262, 282, 302, 322, 342, 362, 382,
            402, 422, 442, 462, 482, 502, 522, 542, 562, 582
        )
        for (page in 1..604) {
            var juz = 1
            for (i in juzStarts.indices) {
                if (page >= juzStarts[i]) {
                    juz = i + 1
                }
            }
            pageJuz[page] = juz
        }
    }

    private fun getSurahName(surahNumber: Int): String {
        val names = listOf(
            "Al-Fatihah", "Al-Baqarah", "Aal-E-Imran", "An-Nisa'", "Al-Ma'idah",
            "Al-An'am", "Al-A'raf", "Al-Anfal", "At-Tawbah", "Yunus", "Hud", 
            "Yusuf", "Ar-Ra'd", "Ibrahim", "Al-Hijr", "An-Nahl", "Al-Isra", 
            "Al-Kahf", "Maryam", "Ta-Ha", "Al-Anbiya", "Al-Hajj", "Al-Mu'minun",
            "An-Nur", "Al-Furqan", "Ash-Shu'ara", "An-Naml", "Al-Qasas",
            "Al- 'Ankabut", "Ar-Rum", "Luqman", "As-Sajdah", "Al-Ahzab", "Saba",
            "Fatir", "Ya-Sin", "As-Saffat", "Sad", "Az-Zumar", "Ghafir", "Fussilat",
            "Ash-Shura", "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiyah", "Al-Ahqaf",
            "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf", "Adh-Dhariyat", "At-Tur",
            "An-Najm", "Al-Qamar", "Ar-Rahman", "Al-Waqi'ah", "Al-Hadid",
            "Al-Mujadilah", "Al-Hashr", "Al-Mumtahanah", "As-Saff", "Al-Jumu'ah",
            "Al-Munafiqun", "At-Taghabun", "At-Talaq", "At-Tahrim", "Al-Mulk",
            "Al-Qalam", "Al-Haqqah", "Al-Ma'arij", "Nuh", "Al-Jinn", "Al-Muzzammil",
            "Al-Muddaththir", "Al-Qiyamah", "Al-Insan", "Al-Mursalat", "An-Naba'",
            "An-Nazi'at", "Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin",
            "Al-Inshiqaq", "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghashiyah",
            "Al-Fajr", "Al-Balad", "Ash-Shams", "Al-Layl", "Ad-Duha", "Ash-Sharh",
            "At-Tin", "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah",
            "Al-'Adiyat", "Al-Qari'ah", "At-Takathur", "Al-'Asr", "Al-Humazah",
            "Al-Fil", "Quraysh", "Al-Ma'un", "Al-Kawthar", "Al-Kafirun", 
            "An-Nasr", "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas"
        )
        return names.getOrNull(surahNumber - 1) ?: "Unknown"
    }

    private fun buildPageCache() {
        for (pageNumber in pageData.keys) {
            val rawLines = pageData[pageNumber] ?: continue
            val quranLines = rawLines.entries
                .map { (lineNum, words) -> QuranLine(lineNum, words) }
                .sortedBy { it.lineNumber }
            pageCache[pageNumber] = QuranPage(
                pageNumber = pageNumber,
                lines = quranLines,
                juzNumber = pageJuz[pageNumber] ?: 0,
                surahName = getSurahName(pageSurah[pageNumber] ?: 1)
            )
        }
        // Free raw per-page data — no longer needed after cache is built.
        pageData.clear()
    }

    /**
     * Returns the pre-built [QuranPage] for [pageNumber]. O(1) map lookup — safe to
     * call from the UI thread.
     */
    fun getPage(pageNumber: Int): QuranPage =
        pageCache[pageNumber] ?: QuranPage(pageNumber = pageNumber, lines = emptyList())
}
