# Quran Marker Debug Coordinates System

## Overview

The debug coordinates system allows precise per-page marker debugging and validation by splitting the monolithic `verse_marker_coordinates.json` into 604 individual page files.

## Structure

```
assets/data/
├── verse_marker_coordinates.json          # Production: All pages in one file
└── quran_marker_debug_coordinates/        # Debug: Individual page files
    ├── 1.json                             # Page 1: Al-Fatiha
    ├── 2.json                             # Page 2: Al-Baqara start
    ├── ...
    ├── 600.json                           # Page 600
    ├── 601.json                           # Page 601
    ├── 602.json                           # Page 602
    ├── 603.json                           # Page 603
    └── 604.json                           # Page 604: An-Nas
```

## Usage

### 1. Initialize with Debug Mode

```dart
// In main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize in DEBUG mode (loads per-page files)
  await verseService.init(forceDebugSource: true);
  
  // OR initialize in PRODUCTION mode (default, single JSON file)
  await verseService.init(forceDebugSource: false);
  
  runApp(const QuranImageApp());
}
```

### 2. Runtime Source Switching

```dart
// Switch to debug mode at runtime
await verseService.setDataSource(MarkerDataSource.debug);

// Switch back to production
await verseService.setDataSource(MarkerDataSource.production);

// Check current mode
if (verseService.isDebugMode) {
  print('Using per-page debug files');
}
```

### 3. Loading Markers

```dart
// Sync loading (returns cached data or empty if not loaded)
final markers = verseService.getMarkersForPage(604);

// Async loading (ensures fresh data from per-page file in debug mode)
final markers = await verseService.getMarkersForPageAsync(604);
```

## Debug Mode Benefits

1. **Precise Validation**: Compare individual page markers with Ayah app screenshots
2. **Incremental Updates**: Modify single page coordinates without affecting others
3. **Faster Testing**: Load only the pages you need for debugging
4. **Version Control**: Track changes to specific pages independently

## Generating Debug Files

Run the generation script:

```bash
cd /Users/mohammadkamel/flutter_projects/tilawa_workspace
python3 generate_all_page_files.py
```

This creates all 604 individual JSON files from the master file.

## Environment-Based Configuration

### Using Dart Defines

```bash
# Run in debug mode
flutter run --dart-define=MARKER_SOURCE=debug

# Run in production mode (default)
flutter run --dart-define=MARKER_SOURCE=production
```

### Implementation

```dart
// In main.dart
const markerSource = String.fromEnvironment('MARKER_SOURCE', defaultValue: 'production');

void main() async {
  await verseService.init(
    forceDebugSource: markerSource == 'debug',
  );
  runApp(const QuranImageApp());
}
```

## Testing Specific Pages

### Debug Mode Example

```dart
class DebugMarkerPage extends StatelessWidget {
  final int pageNumber;
  
  const DebugMarkerPage({required this.pageNumber});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: verseService.getMarkersForPageAsync(pageNumber),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final markers = snapshot.data!;
        return Column(
          children: [
            Text('Page $pageNumber - ${markers.length} markers'),
            ...markers.map((m) => Text(
              'Sura ${m.sura}, Ayah ${m.ayah}: x=${m.centerX.toStringAsFixed(4)}',
            )),
          ],
        );
      },
    );
  }
}
```

## Validation Workflow

1. **Enable Debug Mode**: Initialize with `forceDebugSource: true`
2. **Navigate to Page**: Go to the page you want to validate
3. **Compare**: Check marker positions against Ayah app screenshots
4. **Edit**: Modify the specific page JSON file (`{page}.json`)
5. **Hot Restart**: See changes immediately
6. **Repeat**: Until markers align perfectly
7. **Merge**: Copy final coordinates back to master file

## Files

| File | Purpose |
|------|---------|
| `verse_marker_coordinates.json` | Production: All 604 pages in one file |
| `quran_marker_debug_coordinates/{page}.json` | Debug: Individual page files |
| `verse_service.dart` | Updated service with dual source support |
| `generate_all_page_files.py` | Script to generate all 604 page files |

## API Summary

### MarkerDataSource Enum
- `production`: Use single JSON file (default)
- `debug`: Use individual page files

### VerseService Methods
- `init({bool forceDebugSource})`: Initialize service
- `setDataSource(MarkerDataSource)`: Switch sources at runtime
- `getMarkersForPage(int)`: Get markers (sync)
- `getMarkersForPageAsync(int)`: Get markers (async, ensures fresh data)
- `isDebugMode`: Check if in debug mode

## Notes

- Debug mode loads pages on-demand, reducing initial startup time
- Production mode preloads all data for faster page switching
- Hot restart required when switching sources
- Individual page files enable precise Git diffs for coordinate changes
