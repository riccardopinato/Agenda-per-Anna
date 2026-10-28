part of '../../main.dart';

/// A draft-only editor. The canonical preferences are written exactly once,
/// when the user selects Apply. Back/Cancel leaves the store untouched.
class AppearanceColorsScreen extends StatefulWidget {
  final AgendaStore store;

  const AppearanceColorsScreen({super.key, required this.store});

  @override
  State<AppearanceColorsScreen> createState() =>
      _AppearanceColorsScreenState();
}

class _AppearanceColorsScreenState extends State<AppearanceColorsScreen> {
  late AgendaPalette selectedPalette;
  late bool custom;
  late HSVColor hsv;
  late AgendaColorIntensity intensity;
  late final TextEditingController hexController;
  bool saving = false;
  bool hexValid = true;

  @override
  void initState() {
    super.initState();
    final prefs = widget.store.preferences;
    selectedPalette = prefs.palette;
    custom = prefs.useCustomPalette;
    intensity = prefs.colorIntensity;
    hsv = HSVColor.fromColor(Color(prefs.customColorValue | 0xFF000000));
    hexController = TextEditingController(text: _hex(hsv.toColor()));
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  String _hex(Color value) =>
      '#${(value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Color get selectedColor => custom ? hsv.toColor() : selectedPalette.seed;

  void _updateColor(HSVColor next) {
    setState(() {
      hsv = next;
      custom = true;
      hexValid = true;
    });
    final value = _hex(hsv.toColor());
    hexController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _readHex(String raw) {
    final value = raw.trim();
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(() => hexValid = false);
      return;
    }
    final rgb = int.parse(value.replaceFirst('#', ''), radix: 16);
    setState(() {
      hsv = HSVColor.fromColor(Color(0xFF000000 | rgb));
      custom = true;
      hexValid = true;
    });
  }

  Future<void> _apply() async {
    if (saving || !hexValid) return;
    setState(() => saving = true);
    try {
      final current = widget.store.preferences;
      await widget.store.savePreferences(current.copyWith(
        palette: selectedPalette,
        useCustomPalette: custom,
        customColorValue: hsv.toColor().toARGB32(),
        colorIntensity: intensity,
      ));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AnnaStrings.of(context).d3('appearanceSaveError'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: selectedColor,
      brightness: Theme.of(context).brightness,
    );
    final expressive = intensity == AgendaColorIntensity.expressive;
    final previewSurface = expressive
        ? Color.lerp(scheme.surfaceContainerLow, scheme.primaryContainer, 0.30)!
        : scheme.surfaceContainerLowest;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.d3('appearanceColorsTitle')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AnnaDesignTokens.compactContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
            children: [
              Text(strings.d3('appearanceColorsIntro')),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              Semantics(
                header: true,
                child: Text(
                  strings.d3('appearanceSuggested'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final palette in AgendaPalette.values)
                    ChoiceChip(
                      key: ValueKey<String>('appearance-preset-${palette.name}'),
                      selected: !custom && selectedPalette == palette,
                      avatar: CircleAvatar(
                        radius: 9,
                        backgroundColor: palette.seed,
                      ),
                      label: Text(strings.agendaPaletteLabel(palette)),
                      onSelected: (_) {
                        setState(() {
                          selectedPalette = palette;
                          custom = false;
                          // Restore the valid custom draft before leaving its
                          // editor, so a malformed HEX never traps preset use.
                          hexValid = true;
                        });
                        final value = _hex(hsv.toColor());
                        hexController.value = TextEditingValue(
                          text: value,
                          selection: TextSelection.collapsed(offset: value.length),
                        );
                      },
                    ),
                  ChoiceChip(
                    key: const ValueKey<String>('appearance-custom'),
                    selected: custom,
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: hsv.toColor(),
                    ),
                    label: Text(strings.d3('appearanceCustom')),
                    onSelected: (_) => setState(() => custom = true),
                  ),
                ],
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              Text(
                strings.d3('appearanceHueSaturation'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              Semantics(
                label: strings.d3('appearanceSaturationValue'),
                child: _SaturationValueSquare(
                  hsv: hsv,
                  onChanged: (saturation, value) => _updateColor(
                    HSVColor.fromAHSV(
                      1,
                      hsv.hue,
                      saturation,
                      value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceMd),
              Semantics(
                label: strings.d3('appearanceHue'),
                child: _HueStrip(
                  hue: hsv.hue,
                  onChanged: (value) => _updateColor(hsv.withHue(value)),
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceMd),
              // Sliders provide native keyboard focus and VoiceOver/TalkBack
              // increase/decrease actions. The two pointer canvases above
              // remain available for direct manipulation.
              Semantics(
                label: strings.d3('appearanceHueSlider'),
                child: Slider(
                  key: const ValueKey<String>('appearance-hue-slider'),
                  value: hsv.hue.clamp(0.0, 360.0),
                  min: 0,
                  max: 360,
                  divisions: 360,
                  label: '${hsv.hue.round()}°',
                  semanticFormatterCallback: (value) => '${value.round()}°',
                  onChanged: saving
                      ? null
                      : (value) => _updateColor(hsv.withHue(value)),
                ),
              ),
              Semantics(
                label: strings.d3('appearanceSaturationSlider'),
                child: Slider(
                  key: const ValueKey<String>('appearance-saturation-slider'),
                  value: hsv.saturation.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(hsv.saturation * 100).round()}%',
                  semanticFormatterCallback: (value) =>
                      '${(value * 100).round()}%',
                  onChanged: saving
                      ? null
                      : (value) => _updateColor(hsv.withSaturation(value)),
                ),
              ),
              Semantics(
                label: strings.d3('appearanceBrightnessSlider'),
                child: Slider(
                  key: const ValueKey<String>('appearance-brightness-slider'),
                  value: hsv.value.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(hsv.value * 100).round()}%',
                  semanticFormatterCallback: (value) =>
                      '${(value * 100).round()}%',
                  onChanged: saving
                      ? null
                      : (value) => _updateColor(hsv.withValue(value)),
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const ValueKey<String>('appearance-color-swatch'),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(
                        AnnaDesignTokens.radiusSm,
                      ),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('appearance-hex'),
                      controller: hexController,
                      // Do not truncate pasted values before strict HEX validation.
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: strings.d3('appearanceHex'),
                        hintText: '#E98FAA',
                        helperText: strings.d3('appearanceHexHint'),
                        errorText: hexValid
                            ? null
                            : strings.d3('appearanceInvalidHex'),
                        counterText: '',
                      ),
                      onChanged: _readHex,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              Semantics(
                header: true,
                child: Text(
                  strings.d3('appearanceIntensity'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              Wrap(
                spacing: AnnaDesignTokens.spaceSm,
                runSpacing: AnnaDesignTokens.spaceXs,
                children: [
                  ChoiceChip(
                    key: const ValueKey('appearance-delicate'),
                    selected: !expressive,
                    label: Text(strings.d3('appearanceDelicate')),
                    onSelected: (_) => setState(
                      () => intensity = AgendaColorIntensity.delicate,
                    ),
                  ),
                  ChoiceChip(
                    key: const ValueKey('appearance-expressive'),
                    selected: expressive,
                    label: Text(strings.d3('appearanceExpressive')),
                    onSelected: (_) => setState(
                      () => intensity = AgendaColorIntensity.expressive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              Text(
                strings.d3('appearancePreview'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              Container(
                key: const ValueKey<String>('appearance-live-preview'),
                padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
                decoration: BoxDecoration(
                  color: previewSurface,
                  borderRadius: BorderRadius.circular(
                    AnnaDesignTokens.radiusLg,
                  ),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.myDay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.diary,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(
                          AnnaDesignTokens.radiusSm,
                        ),
                      ),
                      child: Text(
                        strings.capture,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceSm),
              Text(
                strings.d3('appearanceDraftHint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey<String>('appearance-reset'),
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: Text(strings.d3('appearanceReset')),
                  onPressed: saving ? null : () {
                    setState(() {
                      selectedPalette = AgendaPalette.rose;
                      custom = false;
                      intensity = AgendaColorIntensity.delicate;
                      hsv = HSVColor.fromColor(AgendaPalette.rose.seed);
                      hexValid = true;
                    });
                    hexController.value = const TextEditingValue(
                      text: '#E98FAA',
                      selection: TextSelection.collapsed(offset: 7),
                    );
                  },
                ),
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: AnnaDesignTokens.spaceSm),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey<String>('appearance-apply'),
                      onPressed: saving || !hexValid ? null : _apply,
                      child: Text(strings.d3('appearanceApply')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AnnaDesignTokens.spaceLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValueSquare extends StatelessWidget {
  final HSVColor hsv;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValueSquare({
    required this.hsv,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 174.0;
        void update(Offset offset) => onChanged(
              (offset.dx / width).clamp(0.0, 1.0),
              (1 - offset.dy / height).clamp(0.0, 1.0),
            );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => update(details.localPosition),
          onPanDown: (details) => update(details.localPosition),
          onPanUpdate: (details) => update(details.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AnnaDesignTokens.radiusSm),
            child: SizedBox(
              height: height,
              width: width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (hsv.saturation * width - 10)
                        .clamp(0.0, width - 20),
                    top: ((1 - hsv.value) * height - 10)
                        .clamp(0.0, height - 20),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HueStrip extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueStrip({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(Offset offset) => onChanged(
              (offset.dx / width * 360).clamp(0.0, 360.0),
            );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => update(details.localPosition),
          onPanDown: (details) => update(details.localPosition),
          onPanUpdate: (details) => update(details.localPosition),
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (hue / 360 * width - 11).clamp(0.0, width - 22),
                  child: Container(
                    width: 22,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
