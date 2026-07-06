import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Drives the physical emergency alarm: a loud looping siren played on the
/// device's *alarm* audio stream (so it's heard even if media/ring volume is
/// low) plus continuous vibration. Singleton — starting it while already
/// ringing is a no-op, so overlapping alerts can't stack two sirens.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ringing = false;

  bool get isRinging => _ringing;

  /// Starts the siren looping at full volume and begins vibrating.
  Future<void> start() async {
    if (_ringing) return;
    _ringing = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Route through the alarm stream so a muted ringer/media doesn't
      // silence a safety alert.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/alarm.wav'));
    } catch (_) {
      // Audio failed (asset missing / platform issue) — vibration below still
      // gives a physical alert, and the on-screen alarm still shows.
    }

    try {
      if (await Vibration.hasVibrator()) {
        // Long insistent pattern, repeated from index 0 until stopped.
        Vibration.vibrate(
          pattern: const [0, 600, 300, 600, 300, 600, 300],
          intensities: const [0, 255, 0, 255, 0, 255, 0],
          repeat: 0,
        );
      }
    } catch (_) {}
  }

  /// Stops the siren and vibration.
  Future<void> stop() async {
    _ringing = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      Vibration.cancel();
    } catch (_) {}
  }
}
