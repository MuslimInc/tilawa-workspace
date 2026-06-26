import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Semantic icon registry for the Tilawa design system.
///
/// This is the single source of truth for every icon in the app.
/// Callers reference `TilawaIcons.search`, never `FluentIcons.search_24_regular`
/// or `Icons.search` directly — keeping the underlying icon font an
/// implementation detail of the ui_kit package.
///
/// Most icons are [IconData] constants for use with the [Icon] widget.
/// For custom SVG icons (e.g. [quran]), use the provided [svg] helper
/// which returns a [Widget] (typically an [SvgPicture]) that can be passed
/// directly as an icon child.
abstract final class TilawaIcons {
  // ── Navigation ──────────────────────────────────────────────────────────────
  static const IconData home = FluentIcons.home_24_regular;
  static const IconData homeActive = FluentIcons.home_24_filled;

  /// The Quran tab icon — a custom open-book SVG from the design system.
  ///
  /// Canonical Quran reader glyph for bottom nav, home shortcuts, and resume.
  ///
  /// Because this is a vector artwork (not a font glyph), it is returned
  /// as a [Widget] via [svg] rather than an [IconData].
  ///
  /// Usage in a bottom bar or button:
  /// ```dart
  /// NavigationDestination(
  ///   icon: TilawaIcons.quran.svg(),
  ///   label: 'Quran',
  /// )
  /// ```
  static const TilawaSvgIcon quran = TilawaSvgIcon(
    'packages/tilawa_ui_kit/assets/icons/quran_icon.svg',
  );

  static const IconData reciters = FluentIcons.headphones_sound_wave_24_regular;
  static const IconData recitersActive =
      FluentIcons.headphones_sound_wave_24_filled;
  static const IconData qibla = FluentIcons.compass_northwest_24_regular;
  static const IconData qiblaActive = FluentIcons.compass_northwest_24_filled;
  static const IconData athkar = FluentIcons.book_open_24_regular;
  static const IconData athkarActive = FluentIcons.book_open_24_filled;

  /// Stylized misbaha (prayer beads) artwork for Home quick actions.
  ///
  /// Multi-color SVG — use [TilawaSvgIcon.colored] so bead hues are preserved.
  static const TilawaSvgIcon athkarMisbaha = TilawaSvgIcon(
    'packages/tilawa_ui_kit/assets/icons/athkar_misbaha_icon.svg',
  );

  /// Monochrome misbaha outline for compact Home tool tiles and nav chrome.
  static const TilawaSvgIcon tasbih = TilawaSvgIcon(
    'packages/tilawa_ui_kit/assets/icons/tasbih_outline_icon.svg',
  );
  static const IconData profile = FluentIcons.person_24_regular;
  static const IconData profileActive = FluentIcons.person_24_filled;

  // ── Actions ─────────────────────────────────────────────────────────────────
  static const IconData search = FluentIcons.search_24_regular;
  static const IconData dismiss = FluentIcons.dismiss_24_regular;
  static const IconData edit = FluentIcons.edit_24_regular;
  static const IconData delete = FluentIcons.delete_24_regular;
  static const IconData share = Icons.share_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData open = FluentIcons.open_24_regular;
  static const IconData reset = FluentIcons.arrow_reset_24_regular;
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData more = FluentIcons.more_vertical_24_regular;
  static const IconData check = Icons.check_rounded;
  static const IconData clearAll = Icons.clear_all_rounded;
  static const IconData copy = Icons.copy;
  static const IconData flag = Icons.flag_rounded;

  // ── Player controls ─────────────────────────────────────────────────────────
  static const IconData playSmall = FluentIcons.play_16_filled;
  static const IconData pauseSmall = FluentIcons.pause_16_filled;
  static const IconData timerSmall = FluentIcons.timer_20_regular;
  static const IconData timerSmallFilled = FluentIcons.timer_20_filled;
  static const IconData play = FluentIcons.play_24_filled;
  static const IconData playLarge = FluentIcons.play_48_filled;
  static const IconData playCircle = FluentIcons.play_circle_24_regular;
  static const IconData pause = FluentIcons.pause_24_filled;
  static const IconData stop = FluentIcons.stop_24_regular;
  static const IconData skipNext = Icons.skip_next;
  static const IconData skipPrevious = Icons.skip_previous;
  static const IconData repeat = Icons.repeat_outlined;
  static const IconData repeatOne = Icons.repeat_one;
  static const IconData shuffle = Icons.shuffle;
  static const IconData speed = Icons.speed_rounded;
  static const IconData volume = Icons.volume_up_outlined;
  static const IconData volumeMute = Icons.volume_mute_outlined;
  static const IconData equalizer = Icons.equalizer;
  static const IconData musicNote = FluentIcons.music_note_2_24_filled;
  static const IconData headphones = reciters;
  static const IconData headphonesActive = recitersActive;
  static const IconData speaker = FluentIcons.speaker_2_24_regular;
  static const IconData reciter = FluentIcons.person_voice_24_regular;
  static const IconData multitrack = Icons.multitrack_audio_rounded;

  // ── Bookmarks / Library ─────────────────────────────────────────────────────
  static const IconData bookmark = FluentIcons.bookmark_24_regular;
  static const IconData bookmarkAdded = Icons.bookmark_added_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData playlist = Icons.playlist_add_rounded;
  static const IconData libraryMusic = Icons.library_music;

  // ── Quran ───────────────────────────────────────────────────────────────────
  static const IconData quranOpen = FluentIcons.book_open_24_regular;
  static const IconData quranOpenFilled = FluentIcons.book_open_24_filled;
  static const IconData audiotrack = Icons.audiotrack_outlined;
  static const IconData autoStories = Icons.auto_stories_rounded;
  static const IconData menuBook = Icons.menu_book_rounded;

  /// Teacher capability / hifz dashboard entry points.
  static const IconData teacherCapability = Icons.school_outlined;

  // ── Prayer times / Qibla ────────────────────────────────────────────────────
  static const IconData location = FluentIcons.location_24_regular;
  static const IconData locationOn = Icons.location_on_rounded;
  static const IconData locationOff = Icons.location_off_rounded;
  static const IconData compass = Icons.explore_outlined;
  static const IconData compassOff = Icons.explore_off_rounded;
  static const IconData mosque = Icons.mosque_rounded;
  static const IconData timer = FluentIcons.timer_24_regular;
  static const IconData timerFilled = FluentIcons.timer_24_filled;
  static const IconData timerOff = Icons.timer_off_outlined;
  static const IconData schedule = Icons.schedule_rounded;
  static const IconData gpsFixed = Icons.gps_fixed_rounded;
  static const IconData myLocation = Icons.my_location_rounded;

  // ── Prayer weather / time-of-day ────────────────────────────────────────────
  static const IconData prayerFajr = FluentIcons.weather_haze_24_regular;
  static const IconData prayerSunrise = FluentIcons.weather_sunny_24_regular;
  static const IconData prayerDhuhr = FluentIcons.weather_sunny_high_24_regular;
  static const IconData prayerAsr = FluentIcons.weather_sunny_low_24_regular;
  static const IconData prayerMaghrib = FluentIcons.weather_moon_24_regular;
  static const IconData prayerIsha = FluentIcons.weather_moon_24_filled;
  static const IconData prayerMidnight =
      FluentIcons.weather_moon_off_24_regular;
  static const IconData prayerLastThird = FluentIcons.star_24_filled;
  static const IconData nightMode = FluentIcons.weather_moon_24_regular;
  static const IconData nightModeOff = FluentIcons.weather_moon_off_24_regular;
  static const IconData bedtime = Icons.bedtime_rounded;
  static const IconData wbSunny = Icons.wb_sunny_rounded;

  // ── Notifications ───────────────────────────────────────────────────────────
  static const IconData notificationsActive =
      Icons.notifications_active_outlined;
  static const IconData notificationsOff = Icons.notifications_off_outlined;
  static const IconData notificationsNone = Icons.notifications_none_rounded;
  static const IconData alarm = Icons.alarm_rounded;

  // ── Status / Feedback ───────────────────────────────────────────────────────
  static const IconData error = FluentIcons.error_circle_24_regular;
  static const IconData errorOutline = Icons.error_outline_rounded;
  static const IconData offline = FluentIcons.wifi_off_24_regular;
  static const IconData checkCircle = FluentIcons.checkmark_circle_24_regular;
  static const IconData checkCircleOutline = Icons.check_circle_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData loading = Icons.hourglass_empty_rounded;
  static const IconData brokenImage = Icons.broken_image_outlined;
  static const IconData cloudOff = Icons.cloud_off_rounded;
  static const IconData offlineBolt = Icons.offline_bolt_rounded;
  static const IconData offlinePin = Icons.offline_pin_rounded;
  static const IconData blockRounded = Icons.block_rounded;
  static const IconData done = Icons.done;
  static const IconData doneAll = Icons.done_all_rounded;

  // ── Settings / Profile ──────────────────────────────────────────────────────
  static const IconData settings = Icons.settings;
  static const IconData color = FluentIcons.color_24_regular;
  static const IconData storage = FluentIcons.storage_24_regular;
  static const IconData code = FluentIcons.code_24_regular;
  static const IconData support = FluentIcons.person_support_24_regular;
  static const IconData camera = FluentIcons.camera_24_regular;
  static const IconData image = FluentIcons.image_24_regular;
  static const IconData gauge = FluentIcons.gauge_24_regular;
  static const IconData bug = FluentIcons.bug_24_regular;
  static const IconData target = FluentIcons.target_24_regular;
  static const IconData person = FluentIcons.person_24_regular;
  static const IconData personFilled = FluentIcons.person_24_filled;
  static const IconData personOff = Icons.person_off_outlined;
  static const IconData phonelinkSetup = Icons.phonelink_setup_rounded;
  static const IconData recordVoiceOver = Icons.record_voice_over_rounded;
  static const IconData textFields = Icons.text_fields;
  static const IconData highQuality = Icons.high_quality_rounded;
  static const IconData graphicEq = Icons.graphic_eq_rounded;
  static const IconData tune = Icons.tune_rounded;
  static const IconData compare = Icons.compare;

  // ── Navigation ─ shell ──────────────────────────────────────────────────────
  static const IconData menu = Icons.menu_rounded;

  // ── Layout / View ───────────────────────────────────────────────────────────
  static const IconData gridView = FluentIcons.grid_24_regular;
  static const IconData listView = FluentIcons.list_24_regular;
  static const IconData chevronRight = FluentIcons.chevron_right_24_filled;
  static const IconData chevronRightSmall =
      FluentIcons.chevron_right_20_regular;
  static const IconData chevronDown = FluentIcons.chevron_down_24_regular;
  static const IconData chevronUp = FluentIcons.chevron_up_24_regular;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData drag = Icons.drag_handle;
  static const IconData layers = FluentIcons.layer_24_regular;
  static const IconData swapVert = Icons.swap_vert_rounded;
  static const IconData formatListBulleted = Icons.format_list_bulleted_rounded;
  static const IconData formatListNumbered = Icons.format_list_numbered_rounded;
  static const IconData viewList = Icons.view_list_rounded;
  static const IconData gridViewMaterial = Icons.grid_view_rounded;

  // ── Support / Charity tiers ─────────────────────────────────────────────────
  static const IconData heart = FluentIcons.heart_24_regular;
  static const IconData drop = FluentIcons.drop_24_regular;
  static const IconData layer = FluentIcons.layer_24_regular;
  static const IconData circle = FluentIcons.circle_24_regular;

  // ── Khatma ──────────────────────────────────────────────────────────────────
  static const IconData khatmaTarget = Icons.menu_book_rounded;
  static const IconData khatmaToday = Icons.today_outlined;
  static const IconData khatmaRestart = Icons.restart_alt_rounded;
  static const IconData autoAwesome = Icons.auto_awesome_rounded;
  static const IconData localFire = Icons.local_fire_department_rounded;
  static const IconData eventBusy = Icons.event_busy_rounded;
  static const IconData calendarToday = Icons.calendar_today_outlined;
  static const IconData accessTime = Icons.access_time;
  static const IconData accessTimeFilled = Icons.access_time_filled;

  // ── Media / Share ───────────────────────────────────────────────────────────
  static const IconData mic = Icons.mic_rounded;
  static const IconData movie = Icons.movie_creation_outlined;
  static const IconData screenshot = Icons.screenshot_rounded;
  static const IconData iosShare = Icons.ios_share_rounded;

  // ── Stars / Ratings ─────────────────────────────────────────────────────────
  static const IconData star = Icons.star_rounded;
  static const IconData starBorder = Icons.star_border_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteBorder = Icons.favorite_border_rounded;

  // ── Misc ────────────────────────────────────────────────────────────────────
  static const IconData restaurant = Icons.restaurant_outlined;
  static const IconData freeBreakfast = Icons.free_breakfast_rounded;
  static const IconData batteryCharging = Icons.battery_charging_full_rounded;
  static const IconData touchApp = Icons.touch_app_rounded;
  static const IconData nights = Icons.nights_stay_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData arrowOutward = Icons.arrow_outward_rounded;
  static const IconData arrowUpward = Icons.arrow_upward_rounded;
  static const IconData editNote = Icons.edit_note_rounded;
  static const IconData searchOff = Icons.search_off_rounded;
  static const IconData downloading = Icons.downloading_rounded;
  static const IconData deleteOutline = Icons.delete_outline_rounded;
  static const IconData deleteSweep = Icons.delete_sweep_rounded;
  static const IconData clearRounded = Icons.close_rounded;
}

/// A package-bundled SVG icon that can be rendered at any size and color.
///
/// Use via [TilawaIcons.quran.svg()] in places where an [IconData] is not
/// available (e.g. custom navigation bars that accept a [Widget] icon).
@immutable
class TilawaSvgIcon {
  const TilawaSvgIcon(this.assetPath);

  final String assetPath;

  /// Returns an [SvgPicture] widget for this icon, tinted with [color]
  /// and sized to [size].
  ///
  /// Both [color] and [size] default to the values from the nearest
  /// [IconTheme] — matching the behaviour of the [Icon] widget.
  ///
  /// When [color] is provided it overrides the [IconTheme] value, which is
  /// useful for callers (e.g. adaptive shells) that already resolved the
  /// foreground colour for the current selection state.
  Widget svg({
    Color? color,
    double? size,
    String? semanticsLabel,
  }) {
    return Builder(
      builder: (context) {
        final iconTheme = IconTheme.of(context);
        final effectiveColor = color ?? iconTheme.color;
        final effectiveSize = size ?? iconTheme.size ?? 24;

        return SvgPicture.asset(
          assetPath,
          width: effectiveSize,
          height: effectiveSize,
          colorFilter: effectiveColor != null
              ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
              : null,
          semanticsLabel: semanticsLabel,
        );
      },
    );
  }

  /// Renders the SVG at [size] without applying a monochrome tint.
  ///
  /// Use for multi-color artwork such as [TilawaIcons.athkarMisbaha].
  Widget colored({
    double? size,
    String? semanticsLabel,
  }) {
    return Builder(
      builder: (context) {
        final iconTheme = IconTheme.of(context);
        final effectiveSize = size ?? iconTheme.size ?? 24;

        return SvgPicture.asset(
          assetPath,
          width: effectiveSize,
          height: effectiveSize,
          semanticsLabel: semanticsLabel,
        );
      },
    );
  }
}
