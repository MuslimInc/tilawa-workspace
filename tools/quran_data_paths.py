"""Shared paths to canonical mushaf JSON (owned by packages/quran_qcf)."""

from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
QCF_FONTS_DIR = WORKSPACE_ROOT / "packages/quran_qcf/assets/quran_fonts"
QPC_V4_JSON = QCF_FONTS_DIR / "qpc-v4.json"
QURAN_PAGE_INDEX_JSON = QCF_FONTS_DIR / "quran_page_index.json"
QURAN_IMAGE_DATA_DIR = WORKSPACE_ROOT / "packages/quran_image/assets/data"
VERSE_MARKER_COORDS_JSON = QURAN_IMAGE_DATA_DIR / "verse_marker_coordinates.json"
