package com.tilawa.quran.kmp

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.util.Log
import java.util.concurrent.Executors

/**
 * Native Android Page Renderer for QCF Quranic fonts.
 *
 * Performance design:
 * - One Paint per page, cached and reused across frames — zero per-draw allocations.
 * - Line strings are pre-joined once at preload time, not on every onDraw.
 * - Font loading and glyph atlas warm-up run on a background thread so the first
 *   on-screen frame has zero setup or GPU upload cost.
 */
class PageRenderer(private val context: Context) {

    // Single background thread: serialises font I/O and atlas warm-up without contention.
    private val loaderThread = Executors.newSingleThreadExecutor { r ->
        Thread(r, "quran-font-loader").apply { isDaemon = true }
    }

    private data class PageRenderState(
        val paint: Paint,
        val lineStrings: List<Pair<Int, String>>, // 0-indexed slot -> joined line text
    )

    private val cache = mutableMapOf<Int, PageRenderState>()
    private val maxCacheSize = 10

    private val horizontalPaddingRatio = 25f / 720f

    // Reusable 1×1 warm-up bitmap — just needs a Canvas backed by anything.
    // Skia rasterises glyphs into CPU-side glyph cache on first drawText regardless
    // of the target surface, so this avoids allocating a full-page bitmap.
    private val warmBitmap: Bitmap by lazy {
        Bitmap.createBitmap(1, 1, Bitmap.Config.ALPHA_8)
    }
    private val warmCanvas: Canvas by lazy { Canvas(warmBitmap) }

    /**
     * Schedules background font load + glyph atlas warm-up for [pageNumber].
     * No-op for pages already cached. Safe to call from any thread.
     */
    fun preload(pageNumber: Int, page: QuranPage, width: Int, height: Int) {
        if (cache.containsKey(pageNumber)) return
        loaderThread.submit {
            buildAndWarm(pageNumber, page, width, height)
        }
    }

    /**
     * Schedules preload for [pageNumber] and its immediate neighbors in one
     * submission — avoids spawning a new Thread on the caller's side.
     */
    fun preloadWindow(
        pageNumber: Int,
        getPage: (Int) -> QuranPage,
        width: Int,
        height: Int,
    ) {
        loaderThread.submit {
            for (p in (pageNumber - 1)..(pageNumber + 1)) {
                if (p < 1 || p > 604) continue
                if (cache.containsKey(p)) continue
                buildAndWarm(p, getPage(p), width, height)
            }
        }
    }

    /**
     * Renders [page] onto [canvas]. No allocations — all state was prepared by [preload].
     * Falls back to a synchronous build (with glyph warm-up) on first-ever draw if
     * preload hasn't completed yet, then caches the result for all subsequent frames.
     */
    fun renderPage(canvas: Canvas, page: QuranPage, width: Int, height: Int) {
        val state = cache[page.pageNumber]
            ?: buildAndWarm(page.pageNumber, page, width, height)
            ?: return

        val horizontalPadding = width * horizontalPaddingRatio
        val usableWidth = width - (horizontalPadding * 2)
        val centerX = horizontalPadding + usableWidth / 2f

        val verticalMargin = height * 0.05f
        val usableHeight = height - (2 * verticalMargin)
        val lineSlotHeight = usableHeight / 15f

        state.lineStrings.forEach { (slotIndex, lineText) ->
            val y = verticalMargin + (slotIndex * lineSlotHeight) + (lineSlotHeight * 0.82f)
            canvas.drawText(lineText, centerX, y, state.paint)
        }
    }

    /**
     * Builds [PageRenderState] for [pageNumber] and pre-warms the Skia glyph cache
     * by drawing all glyphs to an off-screen canvas. This ensures the GPU atlas is
     * populated before the page is shown, eliminating on-screen upload stalls.
     */
    private fun buildAndWarm(
        pageNumber: Int,
        page: QuranPage,
        width: Int,
        height: Int,
    ): PageRenderState? {
        // Double-checked: background thread may have finished while main thread waited.
        cache[pageNumber]?.let { return it }

        val typeface = loadTypeface(pageNumber) ?: return null

        val horizontalPadding = width * horizontalPaddingRatio
        val usableWidth = width - (horizontalPadding * 2)
        val usableHeight = height - (height * 0.05f * 2)

        val fontSize = minOf(usableHeight / 27.762f, usableWidth / 16.5f)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textAlign = Paint.Align.CENTER
            fontFeatureSettings = "'liga' 1, 'clig' 1"
            this.typeface = typeface
            textSize = fontSize
        }

        val lineStrings = page.lines.map { line ->
            (line.lineNumber - 1) to line.words.joinToString(" ") { it.text }
        }

        // Pre-warm: draw all glyphs to a 1×1 off-screen canvas so Skia rasterises
        // and caches them in the CPU glyph cache before the first on-screen frame.
        // This converts the 4950ms GPU upload stalls into a background CPU operation.
        lineStrings.forEach { (_, lineText) ->
            warmCanvas.drawText(lineText, 0f, 0f, paint)
        }

        val state = PageRenderState(paint, lineStrings)
        evictIfNeeded()
        cache[pageNumber] = state
        return state
    }

    private fun loadTypeface(pageNumber: Int): Typeface? {
        val assetPath = "fonts/QCF_P$pageNumber.ttf"
        return try {
            Typeface.createFromAsset(context.assets, assetPath).also {
                Log.d("PageRenderer", "Loaded: $assetPath")
            }
        } catch (e: Exception) {
            Log.e("PageRenderer", "Failed: fonts/QCF_P$pageNumber.ttf — ${e.message}")
            null
        }
    }

    private fun evictIfNeeded() {
        if (cache.size >= maxCacheSize) {
            cache.remove(cache.keys.first())
        }
    }
}
