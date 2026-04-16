package com.tilawa.quran.kmp

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerDefaults
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.Spring
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import android.view.View
import android.graphics.Canvas
import android.util.AttributeSet
import android.content.Context

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun App() {
    val context = LocalContext.current
    val dataProvider = remember { QuranDataProvider(context.assets) }
    val renderer = remember { com.tilawa.quran.kmp.PageRenderer(context) }

    val pagerState = rememberPagerState(initialPage = 0, pageCount = { 604 })
    // derivedStateOf: recomputes only when currentPage changes, not on every scroll offset.
    val currentPageData by remember { derivedStateOf { dataProvider.getPage(pagerState.currentPage + 1) } }

    MaterialTheme {
        Scaffold(
            topBar = {
                CenterAlignedTopAppBar(
                    title = {
                        Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                            Text(
                                text = currentPageData.surahName,
                                style = MaterialTheme.typography.titleLarge
                            )
                            Text(
                                text = "Juz ${currentPageData.juzNumber}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    },
                    colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                        containerColor = androidx.compose.ui.graphics.Color.Transparent
                    )
                )
            },
            bottomBar = {
                BottomAppBar(
                    containerColor = androidx.compose.ui.graphics.Color.Transparent,
                    contentPadding = PaddingValues(0.dp),
                    modifier = Modifier.height(48.dp)
                ) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                        Text(
                            text = "${pagerState.currentPage + 1}",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(androidx.compose.ui.graphics.Color(0xFFFEFEFE))
            ) {
                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize(),
                    reverseLayout = true,
                    // 0: don't compose off-screen neighbor pages during animation —
                    // font/glyph preloading is handled by NativeQuranView independently.
                    beyondViewportPageCount = 0,
                    // Lower spring stiffness → fewer corrective frames during snap settle,
                    // reducing the anim-phase UI-thread cost in the final frames of each swipe.
                    flingBehavior = PagerDefaults.flingBehavior(
                        state = pagerState,
                        snapAnimationSpec = spring(stiffness = Spring.StiffnessMedium),
                    ),
                ) { pageIndex ->
                    val pageNumber = pageIndex + 1
                    val quranPage = remember(pageNumber) { dataProvider.getPage(pageNumber) }

                    QuranPageView(
                        renderer = renderer,
                        page = quranPage,
                        getPage = dataProvider::getPage,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(bottom = 24.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun QuranPageView(
    renderer: com.tilawa.quran.kmp.PageRenderer,
    page: QuranPage,
    getPage: (Int) -> QuranPage,
    modifier: Modifier = Modifier
) {
    AndroidView(
        factory = { ctx ->
            NativeQuranView(ctx).apply {
                this.renderer = renderer
                this.getPage = getPage
            }
        },
        update = { view ->
            view.setPage(page)
        },
        modifier = modifier
    )
}

class NativeQuranView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    var renderer: com.tilawa.quran.kmp.PageRenderer? = null
    var getPage: ((Int) -> QuranPage)? = null
    private var currentPage: QuranPage? = null

    fun setPage(page: QuranPage) {
        if (currentPage?.pageNumber == page.pageNumber) return
        currentPage = page
        // Kick off background preload for this page and its neighbors as soon
        // as we know the view dimensions. width/height are 0 before first layout;
        // onSizeChanged -> invalidate path handles that case via onDraw-time build.
        if (width > 0 && height > 0) {
            preloadNeighbors(page.pageNumber)
        }
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        // View now has real dimensions — preload the current page.
        currentPage?.let { preloadNeighbors(it.pageNumber) }
    }

    private fun preloadNeighbors(pageNumber: Int) {
        val gp = getPage ?: return
        val r = renderer ?: return
        // Single executor submission — no raw Thread spawn overhead on the UI thread.
        r.preloadWindow(pageNumber, gp, width, height)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val page = currentPage ?: return
        renderer?.renderPage(canvas, page, width, height)
    }
}
