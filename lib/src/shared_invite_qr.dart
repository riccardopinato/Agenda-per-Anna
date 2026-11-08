part of '../main.dart';

/// QR is presentation/transport for the existing server-issued 24h code.
/// The client NEVER extends expiry, changes membership or mints an invite.
abstract final class SharedInviteQrPayload {
  static final RegExp _valid = RegExp(r'^[A-Z0-9]{8}$');
  static const String prefix = 'ANNA-DIARY:';

  static String? parse(String? scanned) {
    if (scanned == null) return null;
    final trimmed = scanned.trim().toUpperCase();
    final candidate = trimmed.startsWith(prefix)
        ? trimmed.substring(prefix.length)
        : trimmed;
    return _valid.hasMatch(candidate) ? candidate : null;
  }

  static String encode(String code) {
    final normalized = parse(code);
    if (normalized == null) {
      throw ArgumentError.value(code, 'code', 'Invalid space invitation code');
    }
    return '$prefix$normalized';
  }
}

enum SharedInviteQrStyle { sunset, garden, stars, watercolor }

extension SharedInviteQrStyleVisual on SharedInviteQrStyle {
  String get name => switch (this) {
        SharedInviteQrStyle.sunset => 'Tramonto',
        SharedInviteQrStyle.garden => 'Giardino',
        SharedInviteQrStyle.stars => 'Stelle',
        SharedInviteQrStyle.watercolor => 'Acquerello',
      };

  /// Presentation-only copy: the original eight-character invite is shared
  /// across all four artwork variants and all supported UI languages.
  String labelFor(String languageCode) => sharedInviteQrText(
        languageCode,
        switch (this) {
          SharedInviteQrStyle.sunset => 'styleSunset',
          SharedInviteQrStyle.garden => 'styleGarden',
          SharedInviteQrStyle.stars => 'styleStars',
          SharedInviteQrStyle.watercolor => 'styleWatercolor',
        },
      );

  IconData get icon => switch (this) {
        SharedInviteQrStyle.sunset => Icons.wb_sunny_outlined,
        SharedInviteQrStyle.garden => Icons.local_florist_outlined,
        SharedInviteQrStyle.stars => Icons.nightlight_outlined,
        SharedInviteQrStyle.watercolor => Icons.palette_outlined,
      };

  List<Color> get gradient => switch (this) {
        SharedInviteQrStyle.sunset => const [
            Color(0xFFF4C9B8), Color(0xFFF2E0DD), Color(0xFFDFA2C3),
          ],
        SharedInviteQrStyle.garden => const [
            Color(0xFFCAE2D1), Color(0xFFF6EAD9), Color(0xFFD1E9C9),
          ],
        SharedInviteQrStyle.stars => const [
            Color(0xFFD5DBF1), Color(0xFFF3E8F4), Color(0xFFC4D1F0),
          ],
        SharedInviteQrStyle.watercolor => const [
            Color(0xFFF2D7EA), Color(0xFFEBD8F2), Color(0xFFF6DECF),
          ],
      };
}

String sharedInviteQrText(String locale, String key) {
  final language = switch (locale) {
    'en' => <String, String>{
        'scan': 'Scan QR code', 'instruction': 'Scan an Anna’s Diary invitation',
        'invalid': 'This is not an Anna’s Diary invitation QR',
        'joinTitle': 'Join shared space?', 'joinPrompt': 'Confirm this invitation code',
        'art': 'Change picture', 'classic': 'Classic QR', 'artistic': 'Artistic QR',
        'unavailable': 'Camera not available. Enter the code manually.',
        'styleSunset': 'Sunset', 'styleGarden': 'Garden',
        'styleStars': 'Stars', 'styleWatercolor': 'Watercolor',
      },
    'es' => <String, String>{
        'scan': 'Escanear QR', 'instruction': 'Escanea una invitación de Anna’s Diary',
        'invalid': 'Este QR no es una invitación de Anna’s Diary',
        'joinTitle': '¿Unirse al espacio?', 'joinPrompt': 'Confirma este código',
        'art': 'Cambiar imagen', 'classic': 'QR clásico', 'artistic': 'QR artístico',
        'unavailable': 'Cámara no disponible. Introduce el código a mano.',
        'styleSunset': 'Atardecer', 'styleGarden': 'Jardín',
        'styleStars': 'Estrellas', 'styleWatercolor': 'Acuarela',
      },
    'fr' => <String, String>{
        'scan': 'Scanner le QR', 'instruction': 'Scannez une invitation Anna’s Diary',
        'invalid': 'Ce QR n’est pas une invitation Anna’s Diary',
        'joinTitle': 'Rejoindre cet espace ?', 'joinPrompt': 'Confirmez ce code',
        'art': 'Changer l’image', 'classic': 'QR classique', 'artistic': 'QR artistique',
        'unavailable': 'Caméra indisponible. Saisissez le code.',
        'styleSunset': 'Coucher de soleil', 'styleGarden': 'Jardin',
        'styleStars': 'Étoiles', 'styleWatercolor': 'Aquarelle',
      },
    'pt' => <String, String>{
        'scan': 'Ler código QR', 'instruction': 'Lê um convite do Anna’s Diary',
        'invalid': 'Este QR não é um convite do Anna’s Diary',
        'joinTitle': 'Entrar no espaço?', 'joinPrompt': 'Confirma este código',
        'art': 'Mudar imagem', 'classic': 'QR clássico', 'artistic': 'QR artístico',
        'unavailable': 'Câmara indisponível. Introduz o código.',
        'styleSunset': 'Pôr do sol', 'styleGarden': 'Jardim',
        'styleStars': 'Estrelas', 'styleWatercolor': 'Aguarela',
      },
    _ => <String, String>{
        'scan': 'Scansiona QR', 'instruction': 'Inquadra un invito Anna’s Diary',
        'invalid': 'Questo non è un QR di invito Anna’s Diary',
        'joinTitle': 'Collegarti allo spazio?', 'joinPrompt': 'Conferma questo codice',
        'art': 'Cambia immagine', 'classic': 'QR classico', 'artistic': 'QR artistico',
        'unavailable': 'Fotocamera non disponibile. Inserisci il codice a mano.',
        'styleSunset': 'Tramonto', 'styleGarden': 'Giardino',
        'styleStars': 'Stelle', 'styleWatercolor': 'Acquerello',
      },
  };
  return language[key] ?? key;
}

/// All artwork stays *outside* the QR data modules and quiet zone. This
/// prevents decorative drawing from damaging the encoded 8-character invite.
class SharedInviteQrArtCard extends StatelessWidget {
  final String code;
  final SharedInviteQrStyle style;
  final bool classic;
  final String languageCode;

  const SharedInviteQrArtCard({
    super.key,
    required this.code,
    required this.style,
    required this.classic,
    this.languageCode = 'it',
  });

  @override
  Widget build(BuildContext context) {
    final gradient = classic
        ? const [Colors.white, Color(0xFFF9F8F9)]
        : style.gradient;
    // Artwork always has a pale background, including in dark mode. A fixed
    // dark foreground prevents low-contrast white-on-pastel labels.
    const artworkInk = Color(0xFF332B34);
    // AlertDialog reserves 40dp insets and 24dp content padding per side;
    // the card and QR frame add another 42dp. Avoid a fixed 220dp overflow
    // on 320dp/large-text PWA viewports without altering encoded QR data.
    final qrDimension =
        (MediaQuery.sizeOf(context).width - 180).clamp(0.0, 220.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!classic) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(style.icon, color: artworkInk),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    style.labelFor(languageCode),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: artworkInk, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: QrImageView(
              data: SharedInviteQrPayload.encode(code),
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              size: qrDimension,
              padding: const EdgeInsets.all(7),
              backgroundColor: Colors.white,
              gapless: true,
              errorStateBuilder: (context, error) =>
                  const Icon(Icons.broken_image_outlined, size: 64),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scanner returns a normalized code only; joining happens in the hub after
/// explicit user confirmation and authenticated server-side validation.
class SharedInviteQrScanScreen extends StatefulWidget {
  const SharedInviteQrScanScreen({super.key});

  @override
  State<SharedInviteQrScanScreen> createState() =>
      _SharedInviteQrScanScreenState();
}

class _SharedInviteQrScanScreenState extends State<SharedInviteQrScanScreen> {
  bool _handled = false;
  String? _warning;

  void _onDetect(BarcodeCapture captured) {
    if (_handled) return;
    for (final barcode in captured.barcodes) {
      final raw = barcode.rawValue;
      final parsed = SharedInviteQrPayload.parse(raw);
      if (parsed == null) {
        if (_warning == null && mounted) {
          setState(() => _warning = sharedInviteQrText(
              AnnaStrings.of(context).languageCode, 'invalid'));
        }
        continue;
      }
      _handled = true;
      if (mounted) Navigator.pop(context, parsed);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AnnaStrings.of(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(sharedInviteQrText(language, 'scan')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MobileScanner(
                onDetect: _onDetect,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      sharedInviteQrText(language, 'unavailable'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _warning ?? sharedInviteQrText(language, 'instruction'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
