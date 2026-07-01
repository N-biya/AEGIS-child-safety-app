import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_model.dart';
import '../services/auth_service.dart';
import '../services/emergency_sos_service.dart';
import '../services/firestore_service.dart';
import '../utils/aegis_text.dart';
import '../utils/app_colors.dart';

/// A self-contained emergency SOS button.
///
/// Drop it anywhere in the tree: it loads the linked child and the
/// highest-priority emergency contact on its own, confirms before firing, then
/// captures the phone's GPS and opens an SMS to that contact with a Google-Maps
/// link. No API key, no billing — see [EmergencySosService].
class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  final _firestore = FirestoreService();
  StreamSubscription<ChildModel?>? _childSub;
  ChildModel? _child;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().userId;
    if (uid.isNotEmpty) {
      _childSub = _firestore.watchChildForUser(uid).listen((c) {
        if (mounted) setState(() => _child = c);
      });
    }
  }

  @override
  void dispose() {
    _childSub?.cancel();
    super.dispose();
  }

  EmergencyContactModel? get _contact {
    final contacts = _child?.contactsByPriority ?? const [];
    return contacts.isEmpty ? null : contacts.first;
  }

  Future<void> _onPressed() async {
    if (_busy) return;
    final contact = _contact;

    if (contact == null) {
      _toast('Add an emergency contact in Settings first.', kStress);
      return;
    }

    final confirmed = await _confirm(contact);
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final outcome = await EmergencySosService.sendSos(
      contactPhone: contact.phone,
      childName: _child?.name ?? 'My child',
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!outcome.smsLaunched) {
      _toast('Could not open the messaging app. Please call ${contact.name}.', kAlert);
    } else if (outcome.locationAvailable) {
      _toast('Location sent to ${contact.name} via SMS.', kSafe);
    } else {
      _toast('Couldn\'t get GPS — SMS sent without a location.', kStress);
    }
  }

  Future<bool?> _confirm(EmergencyContactModel contact) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => Dialog(
        backgroundColor: isDark ? kDarkBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAlert.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.sos_rounded, color: kAlert, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Send emergency alert?',
                      style: AegisText.h5(color: T)
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                'This captures your current location and opens a text message to '
                '${contact.name} (${contact.relation}) with a map link.',
                style: AegisText.body(color: D).copyWith(fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: AegisText.label(color: D).copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: kAlert,
                      ),
                      child: Text('Send SOS',
                          style: AegisText.label(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AegisText.body(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFFF43F5E), Color(0xFFB91C3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x66F43F5E), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            else
              const Icon(Icons.sos_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              _busy ? 'Getting location…' : 'SOS',
              style: AegisText.title(color: Colors.white)
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
