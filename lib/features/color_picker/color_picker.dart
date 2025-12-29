import 'package:flutter/material.dart';

import 'palette.dart';
import 'utils.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerHsvColor,
    this.onHsvColorChanged,
    this.paletteType = PaletteType.hsvWithHue,
    this.enableAlpha = true,
    this.labelTypes = const [
      ColorLabelType.rgb,
      ColorLabelType.hsv,
      ColorLabelType.hsl,
    ],
    this.displayThumbColor = false,
    this.portraitOnly = false,
    this.colorPickerWidth = 300.0,
    this.pickerAreaHeightPercent = 1.0,
    this.pickerAreaBorderRadius = BorderRadius.zero,
    this.hexInputBar = false,
    this.hexInputController,
    this.colorHistory,
    this.onHistoryChanged,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final HSVColor? pickerHsvColor;
  final ValueChanged<HSVColor>? onHsvColorChanged;
  final PaletteType paletteType;
  final bool enableAlpha;
  final List<ColorLabelType> labelTypes;
  final bool displayThumbColor;
  final bool portraitOnly;
  final double colorPickerWidth;
  final double pickerAreaHeightPercent;
  final BorderRadius pickerAreaBorderRadius;
  final bool hexInputBar;
  final TextEditingController? hexInputController;
  final List<Color>? colorHistory;
  final ValueChanged<List<Color>>? onHistoryChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);
  List<Color> colorHistory = [];

  @override
  void initState() {
    currentHsvColor = (widget.pickerHsvColor != null)
        ? widget.pickerHsvColor!
        : HSVColor.fromColor(widget.pickerColor);
    if (widget.hexInputController?.text.isEmpty ?? false) {
      widget.hexInputController?.text = colorToHex(
        currentHsvColor.toColor(),
        enableAlpha: widget.enableAlpha,
      );
    }
    widget.hexInputController?.addListener(colorPickerTextInputListener);
    if (widget.colorHistory != null && widget.onHistoryChanged != null) {
      colorHistory = widget.colorHistory ?? [];
    }
    super.initState();
  }

  @override
  void didUpdateWidget(ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickerColor != widget.pickerColor ||
        oldWidget.pickerHsvColor != widget.pickerHsvColor) {
      currentHsvColor = (widget.pickerHsvColor != null)
          ? widget.pickerHsvColor!
          : HSVColor.fromColor(widget.pickerColor);
    }
  }

  void colorPickerTextInputListener() {
    if (widget.hexInputController == null) {
      return;
    }
    final Color? color = colorFromHex(
      widget.hexInputController!.text,
      enableAlpha: widget.enableAlpha,
    );
    if (color != null) {
      setState(() => currentHsvColor = HSVColor.fromColor(color));
      widget.onColorChanged(color);
      if (widget.onHsvColorChanged != null) {
        widget.onHsvColorChanged!(currentHsvColor);
      }
    }
  }

  @override
  void dispose() {
    widget.hexInputController?.removeListener(colorPickerTextInputListener);
    super.dispose();
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(trackType, currentHsvColor, (HSVColor color) {
      widget.hexInputController?.text = colorToHex(
        color.toColor(),
        enableAlpha: widget.enableAlpha,
      );
      setState(() => currentHsvColor = color);
      widget.onColorChanged(currentHsvColor.toColor());
      if (widget.onHsvColorChanged != null) {
        widget.onHsvColorChanged!(currentHsvColor);
      }
    }, displayThumbColor: widget.displayThumbColor);
  }

  void onColorChanging(HSVColor color) {
    widget.hexInputController?.text = colorToHex(
      color.toColor(),
      enableAlpha: widget.enableAlpha,
    );
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor.toColor());
    if (widget.onHsvColorChanged != null) {
      widget.onHsvColorChanged!(currentHsvColor);
    }
  }

  Widget colorPicker() {
    return ClipRRect(
      borderRadius: widget.pickerAreaBorderRadius,
      child: Padding(
        padding: EdgeInsets.all(
          widget.paletteType == PaletteType.hueWheel ? 10 : 0,
        ),
        child: ColorPickerArea(
          currentHsvColor,
          onColorChanging,
          widget.paletteType,
        ),
      ),
    );
  }

  Widget sliderByPaletteType() {
    return switch (widget.paletteType) {
      PaletteType.hsv ||
      PaletteType.hsvWithHue ||
      PaletteType.hsl ||
      PaletteType.hslWithHue => colorPickerSlider(TrackType.hue),
      PaletteType.hsvWithValue ||
      PaletteType.hueWheel => colorPickerSlider(TrackType.value),
      PaletteType.hsvWithSaturation => colorPickerSlider(TrackType.saturation),
      PaletteType.hslWithLightness => colorPickerSlider(TrackType.lightness),
      PaletteType.hslWithSaturation => colorPickerSlider(
        TrackType.saturationForHSL,
      ),
      PaletteType.rgbWithBlue => colorPickerSlider(TrackType.blue),
      PaletteType.rgbWithGreen => colorPickerSlider(TrackType.green),
      PaletteType.rgbWithRed => colorPickerSlider(TrackType.red),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait ||
        widget.portraitOnly) {
      return Column(
        children: <Widget>[
          SizedBox(
            width: widget.colorPickerWidth,
            height: widget.colorPickerWidth * widget.pickerAreaHeightPercent,
            child: colorPicker(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () => setState(() {
                    if (widget.onHistoryChanged != null &&
                        !colorHistory.contains(currentHsvColor.toColor())) {
                      colorHistory.add(currentHsvColor.toColor());
                      widget.onHistoryChanged!(colorHistory);
                    }
                  }),
                  child: ColorIndicator(currentHsvColor),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 40.0,
                        width: widget.colorPickerWidth - 75.0,
                        child: sliderByPaletteType(),
                      ),
                      if (widget.enableAlpha)
                        SizedBox(
                          height: 40.0,
                          width: widget.colorPickerWidth - 75.0,
                          child: colorPickerSlider(TrackType.alpha),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (colorHistory.isNotEmpty)
            SizedBox(
              width: widget.colorPickerWidth,
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  for (final Color color in colorHistory)
                    Padding(
                      key: Key(color.hashCode.toString()),
                      padding: const EdgeInsets.fromLTRB(15, 0, 0, 10),
                      child: Center(
                        child: GestureDetector(
                          onTap: () =>
                              onColorChanging(HSVColor.fromColor(color)),
                          child: ColorIndicator(
                            HSVColor.fromColor(color),
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          if (widget.labelTypes.isNotEmpty)
            FittedBox(
              child: ColorPickerLabel(
                currentHsvColor,
                enableAlpha: widget.enableAlpha,
                colorLabelTypes: widget.labelTypes,
              ),
            ),
          if (widget.hexInputBar)
            ColorPickerInput(currentHsvColor.toColor(), (Color color) {
              setState(() => currentHsvColor = HSVColor.fromColor(color));
              widget.onColorChanged(currentHsvColor.toColor());
              if (widget.onHsvColorChanged != null) {
                widget.onHsvColorChanged!(currentHsvColor);
              }
            }, enableAlpha: widget.enableAlpha),
          const SizedBox(height: 20.0),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          SizedBox(
            width: widget.colorPickerWidth,
            height: widget.colorPickerWidth * widget.pickerAreaHeightPercent,
            child: colorPicker(),
          ),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(width: 20.0),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (widget.onHistoryChanged != null &&
                          !colorHistory.contains(currentHsvColor.toColor())) {
                        colorHistory.add(currentHsvColor.toColor());
                        widget.onHistoryChanged!(colorHistory);
                      }
                    }),
                    child: ColorIndicator(currentHsvColor),
                  ),
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: 40.0,
                        width: 260.0,
                        child: sliderByPaletteType(),
                      ),
                      if (widget.enableAlpha)
                        SizedBox(
                          height: 40.0,
                          width: 260.0,
                          child: colorPickerSlider(TrackType.alpha),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10.0),
                ],
              ),
              if (colorHistory.isNotEmpty)
                SizedBox(
                  width: widget.colorPickerWidth,
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final Color color in colorHistory)
                        Padding(
                          key: Key(color.hashCode.toString()),
                          padding: const EdgeInsets.fromLTRB(15, 18, 0, 0),
                          child: Center(
                            child: GestureDetector(
                              onTap: () =>
                                  onColorChanging(HSVColor.fromColor(color)),
                              onLongPress: () {
                                if (colorHistory.remove(color)) {
                                  widget.onHistoryChanged!(colorHistory);
                                  setState(() {});
                                }
                              },
                              child: ColorIndicator(
                                HSVColor.fromColor(color),
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 15),
                    ],
                  ),
                ),
              const SizedBox(height: 20.0),
              if (widget.labelTypes.isNotEmpty)
                FittedBox(
                  child: ColorPickerLabel(
                    currentHsvColor,
                    enableAlpha: widget.enableAlpha,
                    colorLabelTypes: widget.labelTypes,
                  ),
                ),
              if (widget.hexInputBar)
                ColorPickerInput(currentHsvColor.toColor(), (Color color) {
                  setState(() => currentHsvColor = HSVColor.fromColor(color));
                  widget.onColorChanged(currentHsvColor.toColor());
                  if (widget.onHsvColorChanged != null) {
                    widget.onHsvColorChanged!(currentHsvColor);
                  }
                }, enableAlpha: widget.enableAlpha),
              const SizedBox(height: 5),
            ],
          ),
        ],
      );
    }
  }
}

/// The Color Picker with sliders only. Support HSV, HSL and RGB color model.
class SlidePicker extends StatefulWidget {
  const SlidePicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.colorModel = ColorModel.rgb,
    this.enableAlpha = true,
    this.sliderSize = const Size(260, 40),
    this.showSliderText = true,
    this.showParams = true,
    this.labelTypes = const [],
    this.showIndicator = true,
    this.indicatorSize = const Size(280, 50),
    this.indicatorAlignmentBegin = const Alignment(-1.0, -3.0),
    this.indicatorAlignmentEnd = const Alignment(1.0, 3.0),
    this.displayThumbColor = true,
    this.indicatorBorderRadius = BorderRadius.zero,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final ColorModel colorModel;
  final bool enableAlpha;
  final Size sliderSize;
  final bool showSliderText;
  final bool showParams;
  final List<ColorLabelType> labelTypes;
  final bool showIndicator;
  final Size indicatorSize;
  final AlignmentGeometry indicatorAlignmentBegin;
  final AlignmentGeometry indicatorAlignmentEnd;
  final bool displayThumbColor;
  final BorderRadius indicatorBorderRadius;

  @override
  State<StatefulWidget> createState() => _SlidePickerState();
}

class _SlidePickerState extends State<SlidePicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    super.initState();
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  @override
  void didUpdateWidget(SlidePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickerColor != widget.pickerColor) {
      currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    }
  }

  Widget colorPickerSlider(TrackType trackType) {
    return ColorPickerSlider(
      trackType,
      currentHsvColor,
      (HSVColor color) {
        setState(() => currentHsvColor = color);
        widget.onColorChanged(currentHsvColor.toColor());
      },
      displayThumbColor: widget.displayThumbColor,
      fullThumbColor: true,
    );
  }

  Widget indicator() {
    return ClipRRect(
      borderRadius: widget.indicatorBorderRadius,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GestureDetector(
        onTap: () {
          setState(
            () => currentHsvColor = HSVColor.fromColor(widget.pickerColor),
          );
          widget.onColorChanged(currentHsvColor.toColor());
        },
        child: Container(
          width: widget.indicatorSize.width,
          height: widget.indicatorSize.height,
          margin: const EdgeInsets.only(bottom: 15.0),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.pickerColor,
                widget.pickerColor,
                currentHsvColor.toColor(),
                currentHsvColor.toColor(),
              ],
              begin: widget.indicatorAlignmentBegin,
              end: widget.indicatorAlignmentEnd,
              stops: const [0.0, 0.5, 0.5, 1.0],
            ),
          ),
          child: const CustomPaint(painter: CheckerPainter()),
        ),
      ),
    );
  }

  String getColorParams(int pos) {
    assert(pos >= 0 && pos < 4);
    if (widget.colorModel == ColorModel.rgb) {
      final Color color = currentHsvColor.toColor();
      return [
        (color.r * 255).round().toString(),
        (color.g * 255).round().toString(),
        (color.b * 255).round().toString(),
        '${(color.a * 100).round()}',
      ][pos];
    } else if (widget.colorModel == ColorModel.hsv) {
      return [
        currentHsvColor.hue.round().toString(),
        (currentHsvColor.saturation * 100).round().toString(),
        (currentHsvColor.value * 100).round().toString(),
        (currentHsvColor.alpha * 100).round().toString(),
      ][pos];
    } else if (widget.colorModel == ColorModel.hsl) {
      final HSLColor hslColor = hsvToHsl(currentHsvColor);
      return [
        hslColor.hue.round().toString(),
        (hslColor.saturation * 100).round().toString(),
        (hslColor.lightness * 100).round().toString(),
        (currentHsvColor.alpha * 100).round().toString(),
      ][pos];
    } else {
      return '??';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fontSize = 14;

    final List<TrackType> trackTypes = [
      if (widget.colorModel == ColorModel.hsv) ...[
        TrackType.hue,
        TrackType.saturation,
        TrackType.value,
      ],
      if (widget.colorModel == ColorModel.hsl) ...[
        TrackType.hue,
        TrackType.saturationForHSL,
        TrackType.lightness,
      ],
      if (widget.colorModel == ColorModel.rgb) ...[
        TrackType.red,
        TrackType.green,
        TrackType.blue,
      ],
      if (widget.enableAlpha) ...[TrackType.alpha],
    ];
    final List<SizedBox> sliders = [
      for (final TrackType trackType in trackTypes)
        SizedBox(
          width: widget.sliderSize.width,
          height: widget.sliderSize.height,
          child: Row(
            children: <Widget>[
              if (widget.showSliderText)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    trackType.toString().split('.').last[0].toUpperCase(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              Expanded(child: colorPickerSlider(trackType)),
              if (widget.showParams)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: fontSize * 2 + 5),
                  child: Text(
                    getColorParams(trackTypes.indexOf(trackType)),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.showIndicator) indicator(),
        if (!widget.showIndicator) const SizedBox(height: 20),
        ...sliders,
        const SizedBox(height: 20.0),
        if (widget.labelTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ColorPickerLabel(
              currentHsvColor,
              enableAlpha: widget.enableAlpha,
              colorLabelTypes: widget.labelTypes,
            ),
          ),
      ],
    );
  }
}

/// The Color Picker with HUE Ring & HSV model.
class HueRingPicker extends StatefulWidget {
  const HueRingPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.portraitOnly = false,
    this.colorPickerHeight = 250.0,
    this.hueRingStrokeWidth = 20.0,
    this.enableAlpha = false,
    this.displayThumbColor = true,
    this.pickerAreaBorderRadius = BorderRadius.zero,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool portraitOnly;
  final double colorPickerHeight;
  final double hueRingStrokeWidth;
  final bool enableAlpha;
  final bool displayThumbColor;
  final BorderRadius pickerAreaBorderRadius;

  @override
  State<HueRingPicker> createState() => _HueRingPickerState();
}

class _HueRingPickerState extends State<HueRingPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    super.initState();
  }

  @override
  void didUpdateWidget(HueRingPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickerColor != widget.pickerColor) {
      currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    }
  }

  void onColorChanging(HSVColor color) {
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait ||
        widget.portraitOnly) {
      return Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: widget.pickerAreaBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  SizedBox(
                    width: widget.colorPickerHeight,
                    height: widget.colorPickerHeight,
                    child: ColorPickerHueRing(
                      currentHsvColor,
                      onColorChanging,
                      displayThumbColor: widget.displayThumbColor,
                      strokeWidth: widget.hueRingStrokeWidth,
                    ),
                  ),
                  SizedBox(
                    width: widget.colorPickerHeight / 1.6,
                    height: widget.colorPickerHeight / 1.6,
                    child: ColorPickerArea(
                      currentHsvColor,
                      onColorChanging,
                      PaletteType.hsv,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.enableAlpha)
            SizedBox(
              height: 40.0,
              width: widget.colorPickerHeight,
              child: ColorPickerSlider(
                TrackType.alpha,
                currentHsvColor,
                onColorChanging,
                displayThumbColor: widget.displayThumbColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 10),
                ColorIndicator(currentHsvColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                    child: ColorPickerInput(
                      currentHsvColor.toColor(),
                      (Color color) {
                        setState(
                          () => currentHsvColor = HSVColor.fromColor(color),
                        );
                        widget.onColorChanged(currentHsvColor.toColor());
                      },
                      enableAlpha: widget.enableAlpha,
                      embeddedText: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              width: 300.0,
              height: widget.colorPickerHeight,
              child: ClipRRect(
                borderRadius: widget.pickerAreaBorderRadius,
                child: ColorPickerArea(
                  currentHsvColor,
                  onColorChanging,
                  PaletteType.hsv,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: widget.pickerAreaBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                alignment: AlignmentDirectional.topCenter,
                children: <Widget>[
                  SizedBox(
                    width:
                        widget.colorPickerHeight -
                        widget.hueRingStrokeWidth * 2,
                    height:
                        widget.colorPickerHeight -
                        widget.hueRingStrokeWidth * 2,
                    child: ColorPickerHueRing(
                      currentHsvColor,
                      onColorChanging,
                      strokeWidth: widget.hueRingStrokeWidth,
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(height: widget.colorPickerHeight / 8.5),
                      ColorIndicator(currentHsvColor),
                      const SizedBox(height: 10),
                      ColorPickerInput(
                        currentHsvColor.toColor(),
                        (Color color) {
                          setState(
                            () => currentHsvColor = HSVColor.fromColor(color),
                          );
                          widget.onColorChanged(currentHsvColor.toColor());
                        },
                        enableAlpha: widget.enableAlpha,
                        embeddedText: true,
                        disable: true,
                      ),
                      if (widget.enableAlpha) const SizedBox(height: 5),
                      if (widget.enableAlpha)
                        SizedBox(
                          height: 40.0,
                          width:
                              (widget.colorPickerHeight -
                                  widget.hueRingStrokeWidth * 2) /
                              2,
                          child: ColorPickerSlider(
                            TrackType.alpha,
                            currentHsvColor,
                            onColorChanging,
                            displayThumbColor: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}
