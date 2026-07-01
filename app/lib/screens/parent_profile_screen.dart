import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/aegis_form.dart';

// ── Inline SVG icon helpers ───────────────────────────────────────────────
String _hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _personSvg(Color c) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="8" r="4" stroke="${_hexOf(c)}" stroke-width="2"/>
  <path d="M4 21a8 8 0 0116 0" stroke="${_hexOf(c)}" stroke-width="2"
        stroke-linecap="round"/>
</svg>''';

// ─────────────────────────────────────────────────────────────────────────────
class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  String _relation = '';

  static const _relations = ['Mother', 'Father', 'Guardian'];

  String? _photoPath;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameFocus.addListener(() => setState(() {}));
  }

  Future<void> _loadProfile() async {
    final data = await PrefsService.getProfile();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = data['name']     ?? '';
      _relation      = data['relation'] ?? '';
      _photoPath     = data['photo']?.isEmpty == true ? null : data['photo'];
      _loading       = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImagePickerSheet(
        onGallery: () async {
          Navigator.pop(ctx);
          try {
            final file = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (file != null && mounted) {
              setState(() => _photoPath = file.path);
              await PrefsService.saveProfilePhoto(file.path);
            }
          } catch (_) {}
        },
        onCamera: () async {
          Navigator.pop(ctx);
          try {
            final file = await ImagePicker().pickImage(source: ImageSource.camera);
            if (file != null && mounted) {
              setState(() => _photoPath = file.path);
              await PrefsService.saveProfilePhoto(file.path);
            }
          } catch (_) {}
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PrefsService.saveProfile(
      name:     _nameCtrl.text.trim(),
      relation: _relation,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile saved!', style: AegisText.body(color: Colors.white)),
        backgroundColor: kSafe,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.of(context).pop();
  }

  // ── Helper: build one labelled field ──────────────────────────────────────
  Widget _field(
    BuildContext context,
    String label,
    TextEditingController ctrl,
    FocusNode focus,
    String Function(Color) svgFn, {
    TextInputType keyboard = TextInputType.text,
  }) {
    final isFocused = focus.hasFocus;
    final D         = AegisT.textDim(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AegisFieldLabel(label),
        const SizedBox(height: 6),
        AegisTextField(
          controller:   ctrl,
          focusNode:    focus,
          isFocused:    isFocused,
          iconSvg:      svgFn(isFocused ? kAccent : D),
          keyboardType: keyboard,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? const Color(0x0FFFFFFF)
                                : const Color(0xB3FFFFFF),
                            border: Border.all(color: AegisT.glassBorder(context)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: T),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'My Profile',
                        style: AegisText.h5(color: T).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Scrollable body ───────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: kAccent))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 48),
                          child: Column(
                            children: [
                              // Profile avatar
                              Center(
                                child: _ProfileAvatar(
                                  photoPath: _photoPath,
                                  initials:  _nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text[0].toUpperCase()
                                      : 'P',
                                  onTap: _pickImage,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Form card
                              AegisFormCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _field(context, 'FULL NAME',
                                        _nameCtrl, _nameFocus, _personSvg,
                                        keyboard: TextInputType.name),
                                    const SizedBox(height: 16),
                                    Text(
                                      'YOUR RELATION TO YOUR CHILD',
                                      style: AegisText.label(color: D).copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _relations.map((r) {
                                        final selected = _relation == r;
                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() => _relation = r),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: selected
                                                  ? kAccent
                                                  : (isDark
                                                      ? const Color(0x0FFFFFFF)
                                                      : const Color(
                                                          0x0A7C3AED)),
                                            ),
                                            child: Text(r,
                                                style: AegisText.label(
                                                        color: selected
                                                            ? Colors.white
                                                            : D)
                                                    .copyWith(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 22),

                                    AegisPrimaryButton(
                                      label:   'Save Changes',
                                      loading: _saving,
                                      onTap:   _save,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

// ── Circular profile avatar ────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String? photoPath;
  final String  initials;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.photoPath,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFF43F5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4DF43F5E), blurRadius: 24, offset: Offset(0, 8))
              ],
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(photoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : Center(
                    child: Text(
                      initials,
                      style: AegisText.h2(color: Colors.white).copyWith(
                          fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kAccent,
              boxShadow: [
                BoxShadow(color: Color(0x4D7C3AED), blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 15),
          ),
        ],
      ),
    );
  }
}

// ── Image picker bottom sheet ─────────────────────────────────────────────────
class _ImagePickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ImagePickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final isDark      = AegisT.isDark(context);
    final T           = AegisT.text(context);
    final cardBg      = isDark ? kDarkBg : Colors.white;
    final cardBorder  = isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardBg,
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Change Photo',
              style: AegisText.h5(color: T).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _PickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: onGallery),
          const SizedBox(height: 10),
          _PickerOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: onCamera),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AegisT.isDark(context)
              ? const Color(0x0FFFFFFF)
              : const Color(0x0F7C3AED),
          border: Border.all(color: AegisT.glassBorder(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kAccent),
            const SizedBox(width: 12),
            Text(label,
                style: AegisText.body(color: T)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
