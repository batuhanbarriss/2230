import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ============================================================================
// SUPABASE YAPILANDIRMASI
// ============================================================================
const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(OurSpaceApp(prefs: prefs));
}

final supabase = Supabase.instance.client;

// ============================================================================
// UYGULAMA TEMA VE BAŞLANGIÇ
// ============================================================================
class OurSpaceApp extends StatelessWidget {
  final SharedPreferences prefs;
  const OurSpaceApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final String? savedPin = prefs.getString('app_pin');

    return MaterialApp(
      title: 'Our Space',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1128),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9EF01A),
          surface: Color(0xFF141F36),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: savedPin != null && savedPin.isNotEmpty
          ? PinLockScreen(
              prefs: prefs,
              mode: PinMode.verify,
              correctPin: savedPin,
              onSuccess: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MainNavigationScreen(prefs: prefs),
                  ),
                );
              },
            )
          : MainNavigationScreen(prefs: prefs),
    );
  }
}

// ============================================================================
// 1. PIN KİLİDİ & GÜVENLİK EKRANI
// ============================================================================
enum PinMode { verify, setup }

class PinLockScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final PinMode mode;
  final String? correctPin;
  final VoidCallback? onSuccess;
  final Function(String newPin)? onPinCreated;

  const PinLockScreen({
    super.key,
    required this.prefs,
    required this.mode,
    this.correctPin,
    this.onSuccess,
    this.onPinCreated,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String? _firstEnteredPin;
  String _errorMessage = '';

  void _handleNumberPress(String number) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += number;
      _errorMessage = '';
    });

    if (_enteredPin.length == 4) {
      _evaluatePin();
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _evaluatePin() {
    if (widget.mode == PinMode.verify) {
      if (_enteredPin == widget.correctPin) {
        widget.onSuccess?.call();
      } else {
        setState(() {
          _errorMessage = 'Hatalı PIN! Lütfen tekrar deneyin.';
          _enteredPin = '';
        });
      }
    } else if (widget.mode == PinMode.setup) {
      if (_firstEnteredPin == null) {
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        if (_enteredPin == _firstEnteredPin) {
          widget.onPinCreated?.call(_enteredPin);
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = 'PIN kodları eşleşmedi. Tekrar deneyin.';
            _enteredPin = '';
            _firstEnteredPin = null;
          });
        }
      }
    }
  }

  String _getTitleText() {
    if (widget.mode == PinMode.verify) {
      return 'Özel Alanımıza Hoş Geldin ✨';
    } else {
      return _firstEnteredPin == null ? 'Yeni PIN Belirleyin' : 'PIN Kodunu Onaylayın';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9EF01A).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFF9EF01A), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              _getTitleText(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mode == PinMode.verify
                  ? 'Giriş yapmak için 4 haneli PIN kodunuzu girin'
                  : '4 haneli güvenlik kodunuzu tuşlayın',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFF9EF01A) : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? const Color(0xFF9EF01A) : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var col = 1; col <= 3; col++)
                            _buildKeyButton('${row * 3 + col}'),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.mode != PinMode.verify)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28),
                            onPressed: () => Navigator.pop(context),
                          )
                        else
                          const SizedBox(width: 64),
                        _buildKeyButton('0'),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 26),
                          onPressed: _handleBackspace,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton(String text) {
    return InkWell(
      onTap: () => _handleNumberPress(text),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF141F36),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ANA GEZİNME EKRANI (TABS + AYARLAR BUTONU)
// ============================================================================
class MainNavigationScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const MainNavigationScreen({super.key, required this.prefs});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late String _userName;
  late String _partnerName;
  late DateTime _anniversaryDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _userName = widget.prefs.getString('user_name') ?? 'Batuhan';
    _partnerName = widget.prefs.getString('partner_name') ?? 'Sevgilim';
    final savedDate = widget.prefs.getString('anniversary_date');
    if (savedDate != null) {
      _anniversaryDate = DateTime.tryParse(savedDate) ?? DateTime(2023, 1, 1);
    } else {
      _anniversaryDate = DateTime(2023, 1, 1);
    }
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141F36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => AppSettingsModal(
        prefs: widget.prefs,
        userName: _userName,
        partnerName: _partnerName,
        anniversaryDate: _anniversaryDate,
        onSettingsUpdated: () {
          setState(() {
            _loadSettings();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MomentsTimelineScreen(
        userName: _userName,
        partnerName: _partnerName,
        anniversaryDate: _anniversaryDate,
        onUpdateAnniversary: (newDate) {
          widget.prefs.setString('anniversary_date', newDate.toIso8601String());
          setState(() => _anniversaryDate = newDate);
        },
        onOpenSettings: _openSettingsModal,
      ),
      ChatScreen(currentUserName: _userName, onOpenSettings: _openSettingsModal),
      SharedNotesScreen(onOpenSettings: _openSettingsModal),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F1A30),
        selectedItemColor: const Color(0xFF9EF01A),
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Anılar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_heart_rounded),
            label: 'Planlar',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ANILAR & FOTOĞRAFLAR
// ============================================================================
class MomentsTimelineScreen extends StatelessWidget {
  final String userName;
  final String partnerName;
  final DateTime anniversaryDate;
  final Function(DateTime) onUpdateAnniversary;
  final VoidCallback onOpenSettings;

  const MomentsTimelineScreen({
    super.key,
    required this.userName,
    required this.partnerName,
    required this.anniversaryDate,
    required this.onUpdateAnniversary,
    required this.onOpenSettings,
  });

  Future<void> _uploadNewMoment(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null || !context.mounted) return;

    final titleController = TextEditingController();
    final noteController = TextEditingController();
    bool isUploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141F36),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Anı Ekle ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Başlık (örn: Birlikte İlk Tatilimiz)',
                  filled: true,
                  fillColor: const Color(0xFF0A1128),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Bu ana dair kalpten bir not...',
                  filled: true,
                  fillColor: const Color(0xFF0A1128),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9EF01A),
                  foregroundColor: const Color(0xFF0A1128),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isUploading
                    ? null
                    : () async {
                        setModalState(() => isUploading = true);
                        try {
                          final bytes = await pickedFile.readAsBytes();
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

                          await supabase.storage.from('photos').uploadBinary(
                                fileName,
                                bytes,
                                fileOptions: const FileOptions(contentType: 'image/jpeg'),
                              );
                          final imageUrl = supabase.storage.from('photos').getPublicUrl(fileName);

                          await supabase.from('moments').insert({
                            'title': titleController.text.trim().isEmpty ? 'Özel Bir An' : titleController.text.trim(),
                            'note': noteController.text.trim(),
                            'image_url': imageUrl,
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setModalState(() => isUploading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Yükleme hatası: $e')),
                            );
                          }
                        }
                      },
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)),
                      )
                    : const Text('Anıyı Paylaş', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bizim Hikayemiz', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Ayarlar ve Profil',
            onPressed: onOpenSettings,
          ),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF9EF01A)),
            tooltip: 'Yeni Anı Ekle',
            onPressed: () => _uploadNewMoment(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AnniversaryCounterCard(
                userName: userName,
                partnerName: partnerName,
                startDate: anniversaryDate,
                onSelectDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: anniversaryDate,
                    firstDate: DateTime(1990),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF9EF01A),
                            onPrimary: Color(0xFF0A1128),
                            surface: Color(0xFF141F36),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onUpdateAnniversary(picked);
                  }
                },
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('moments').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF9EF01A))),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('Henüz eklenmiş bir fotoğraf yok ✨', style: TextStyle(color: Colors.white54)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return MomentItemCard(item: item);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. YILDÖNÜMÜ & BİRLİKTELİK KARTI
// ============================================================================
class AnniversaryCounterCard extends StatelessWidget {
  final String userName;
  final String partnerName;
  final DateTime startDate;
  final VoidCallback onSelectDate;

  const AnniversaryCounterCard({
    super.key,
    required this.userName,
    required this.partnerName,
    required this.startDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    final daysTogether = difference.inDays;

    var nextAnniversary = DateTime(now.year, startDate.month, startDate.day);
    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(now.year + 1, startDate.month, startDate.day);
    }
    final daysUntilNext = nextAnniversary.difference(now).inDays;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162544), Color(0xFF0F1A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF9EF01A).withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9EF01A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                  ),
                  Text(partnerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              InkWell(
                onTap: onSelectDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF9EF01A), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(startDate),
                        style: const TextStyle(color: Color(0xFF9EF01A), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$daysTogether',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9EF01A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Gündür Birlikteyiz ❤️',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              daysUntilNext == 0
                  ? '🎉 Bugün Yıldönümümüz! Mutlu Yıllar! 🎉'
                  : 'Sonraki yıldönümüne $daysUntilNext gün kaldı ✨',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. TEKİL ANI KARTI (FOTOĞRAF GÖRÜNTÜLEYİCİ VE SİLME BUTONU)
// ============================================================================
class MomentItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const MomentItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr = item['created_at'] != null
        ? DateFormat('d MMMM yyyy').format(DateTime.parse(item['created_at']).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(moment: item),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Hero(
                    tag: 'moment_image_${item['id']}',
                    child: Image.network(
                      item['image_url'],
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 40),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'Özel An',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                  ],
                ),
                if ((item['note'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item['note'],
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. TAM EKRAN FOTOĞRAF GÖRÜNTÜLEYİCİ & SİLME (PINCH-TO-ZOOM)
// ============================================================================
class FullScreenImageViewer extends StatelessWidget {
  final Map<String, dynamic> moment;
  const FullScreenImageViewer({super.key, required this.moment});

  Future<void> _deleteMoment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141F36),
        title: const Text('Bu Anıyı Sil?'),
        content: const Text('Bu fotoğraf ve not kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final imageUrl = moment['image_url'] as String;
        final uri = Uri.parse(imageUrl);
        final fileName = uri.pathSegments.last;

        await supabase.storage.from('photos').remove([fileName]);
        await supabase.from('moments').delete().eq('id', moment['id']);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anı başarıyla silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Anıyı Sil',
            onPressed: () => _deleteMoment(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: 'moment_image_${moment['id']}',
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  moment['image_url'],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moment['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if ((moment['note'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      moment['note'],
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. CANLI MESAJLAŞMA (SAATLİ, OTO-KAYDIRMALI, SİLME DESTEKLİ)
// ============================================================================
class ChatScreen extends StatefulWidget {
  final String currentUserName;
  final VoidCallback onOpenSettings;

  const ChatScreen({super.key, required this.currentUserName, required this.onOpenSettings});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await supabase.from('messages').insert({
      'content': text,
      'sender_name': widget.currentUserName,
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteMessage(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141F36),
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await supabase.from('messages').delete().eq('id', id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Özel Sohbet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Giriş yapılan: ${widget.currentUserName}',
              style: const TextStyle(color: Color(0xFF9EF01A), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF9EF01A)));
                }
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('İlk mesajı sen bırak ❤️', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_name'] == widget.currentUserName;
                    final timeStr = msg['created_at'] != null
                        ? DateFormat('HH:mm').format(DateTime.parse(msg['created_at']).toLocal())
                        : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe ? () => _deleteMessage(msg['id']) : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF9EF01A) : const Color(0xFF141F36),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    msg['sender_name'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF9EF01A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? const Color(0xFF0A1128) : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: isMe ? const Color(0xFF0A1128).withValues(alpha: 0.6) : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Bir mesaj bırak...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF141F36),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF9EF01A),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF0A1128), size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. ORTAK DİLEK VE PLANLAR (CHECKBOX + SİLME)
// ============================================================================
class SharedNotesScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const SharedNotesScreen({super.key, required this.onOpenSettings});

  Future<void> _addPlan(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141F36),
        title: const Text('Ortak Plan Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Birlikte ne yapacağız? (örn: Kamp yapmak)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await supabase.from('shared_plans').insert({'title': controller.text.trim()});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ekle', style: TextStyle(color: Color(0xFF9EF01A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dilekler & Planlar', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            onPressed: onOpenSettings,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF9EF01A)),
            tooltip: 'Yeni Plan Ekle',
            onPressed: () => _addPlan(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('shared_plans').stream(primaryKey: ['id']).order('created_at', ascending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF9EF01A)));
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return const Center(child: Text('Henüz bir plan eklenmemiş ✨', style: TextStyle(color: Colors.white54)));
          }

          final completedCount = plans.where((p) => (p['is_done'] as bool?) ?? false).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '$completedCount / ${plans.length} Tamamlandı',
                      style: const TextStyle(color: Color(0xFF9EF01A), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isDone = (plan['is_done'] as bool?) ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141F36),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IconButton(
                          icon: Icon(
                            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isDone ? const Color(0xFF9EF01A) : Colors.white38,
                          ),
                          onPressed: () async {
                            await supabase.from('shared_plans').update({'is_done': !isDone}).eq('id', plan['id']);
                          },
                        ),
                        title: Text(
                          plan['title'] ?? '',
                          style: TextStyle(
                            color: isDone ? Colors.white38 : Colors.white,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            fontSize: 15,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                          onPressed: () async {
                            await supabase.from('shared_plans').delete().eq('id', plan['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 9. AYARLAR & PROFİL MODALI (PIN KİLİDİ, İSİMLER, TARİH)
// ============================================================================
class AppSettingsModal extends StatefulWidget {
  final SharedPreferences prefs;
  final String userName;
  final String partnerName;
  final DateTime anniversaryDate;
  final VoidCallback onSettingsUpdated;

  const AppSettingsModal({
    super.key,
    required this.prefs,
    required this.userName,
    required this.partnerName,
    required this.anniversaryDate,
    required this.onSettingsUpdated,
  });

  @override
  State<AppSettingsModal> createState() => _AppSettingsModalState();
}

class _AppSettingsModalState extends State<AppSettingsModal> {
  late TextEditingController _userController;
  late TextEditingController _partnerController;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.userName);
    _partnerController = TextEditingController(text: widget.partnerName);
    _hasPin = (widget.prefs.getString('app_pin') ?? '').isNotEmpty;
  }

  void _saveNames() {
    widget.prefs.setString('user_name', _userController.text.trim());
    widget.prefs.setString('partner_name', _partnerController.text.trim());
    widget.onSettingsUpdated();
  }

  void _togglePin(bool value) {
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinLockScreen(
            prefs: widget.prefs,
            mode: PinMode.setup,
            onPinCreated: (newPin) {
              widget.prefs.setString('app_pin', newPin);
              setState(() => _hasPin = true);
              widget.onSettingsUpdated();
            },
          ),
        ),
      );
    } else {
      widget.prefs.remove('app_pin');
      setState(() => _hasPin = false);
      widget.onSettingsUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Uygulama Ayarları ⚙️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Kullanıcı & Profil', style: TextStyle(color: Color(0xFF9EF01A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _userController,
            onChanged: (_) => _saveNames(),
            decoration: InputDecoration(
              labelText: 'Bu Cihazdaki İsim (Sen)',
              filled: true,
              fillColor: const Color(0xFF0A1128),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _partnerController,
            onChanged: (_) => _saveNames(),
            decoration: InputDecoration(
              labelText: 'Sevgilinin İsmi',
              filled: true,
              fillColor: const Color(0xFF0A1128),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Güvenlik', style: TextStyle(color: Color(0xFF9EF01A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('4 Haneli PIN Kilidi'),
            subtitle: Text(
              _hasPin ? 'PIN kilidi devrede' : 'PIN koruması kapalı',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            value: _hasPin,
            activeColor: const Color(0xFF9EF01A),
            onChanged: _togglePin,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
