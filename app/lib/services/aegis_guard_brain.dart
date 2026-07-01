import '../utils/vitals_snapshot.dart';

/// AEGIS Guard — an on-device, rule-based assistant that answers a parent's
/// questions about their child using the *real* sensor data in [VitalsSnapshot]
/// plus a small child-wellbeing knowledge base.
///
/// Everything runs locally: no API calls, no cloud, fully deterministic. It
/// detects the intent behind a message, then composes a grounded answer that
/// always reflects the same numbers shown on the Trends screen.
class AegisGuardBrain {
  final VitalsSnapshot s;
  AegisGuardBrain(this.s);

  static const _day = Duration(days: 1);
  static const _week = Duration(days: 7);

  /// Opening message shown when a fresh conversation starts.
  String greeting() {
    final name = s.childName;
    if (!s.hasData) {
      return "Hi! I'm AEGIS Guard 🛡️ — your private, on-device assistant for "
          "$name. I'll start sharing insights as soon as the band sends "
          'readings. In the meantime, ask me anything about child wellbeing.';
    }
    final hr = s.latest!.heartRate;
    return "Hi! I'm AEGIS Guard 🛡️ — I look after $name's readings right here on "
        "your phone, nothing is sent to the cloud. Right now $name's heart rate "
        "is $hr bpm and everything looks ${_overallWord()}. What would you like "
        'to know?';
  }

  /// Contextual starter questions for the suggestion chips.
  List<String> suggestions() => [
        "How is ${s.childName} doing?",
        'Any stress today?',
        "What's the heart rate?",
        'Tips for a calmer evening',
      ];

  // ── Main entry ──────────────────────────────────────────────────────────
  String reply(String raw) {
    final m = raw.toLowerCase().trim();
    if (m.isEmpty) return "I'm here — ask me anything about ${s.childName}.";

    switch (_classify(m)) {
      case _Intent.greeting:    return _greetingReply();
      case _Intent.help:        return _helpReply();
      case _Intent.overall:     return _overallReply();
      case _Intent.heart:       return _heartReply();
      case _Intent.oxygen:      return _oxygenReply();
      case _Intent.temperature: return _tempReply();
      case _Intent.stress:      return _stressReply();
      case _Intent.sleep:       return _sleepReply();
      case _Intent.activity:    return _activityReply();
      case _Intent.alerts:      return _alertsReply();
      case _Intent.location:    return _locationReply();
      case _Intent.trend:       return _trendReply();
      case _Intent.advice:      return _adviceReply(m);
      case _Intent.thanks:      return _thanksReply();
      case _Intent.unknown:     return _fallbackReply();
    }
  }

  // ── Intent classification ────────────────────────────────────────────────
  _Intent _classify(String m) {
    // Advice topics are checked first when an emotional/behaviour keyword is
    // present, so "my child is anxious" routes to guidance, not a vitals dump.
    if (_hasAny(m, _adviceKeywords.values.expand((v) => v))) {
      return _Intent.advice;
    }
    if (_hasAny(m, ['thank', 'thanks', 'appreciate', 'helpful'])) return _Intent.thanks;
    if (_isGreeting(m)) return _Intent.greeting;
    if (_hasAny(m, ['what can you', 'who are you', 'help', 'how do you', 'what do you do'])) {
      return _Intent.help;
    }
    if (_hasAny(m, ['heart', 'pulse', 'bpm', 'heartbeat', 'heart rate', ' hr'])) {
      return _Intent.heart;
    }
    if (_hasAny(m, ['oxygen', 'spo2', 'spo₂', 'breath', 'o2', 'lungs'])) {
      return _Intent.oxygen;
    }
    if (_hasAny(m, ['temp', 'fever', 'hot', 'warm', 'cold', 'temperature'])) {
      return _Intent.temperature;
    }
    if (_hasAny(m, ['stress', 'calm', 'tense', 'relax', 'agitat'])) return _Intent.stress;
    if (_hasAny(m, ['sleep', 'nap', 'bedtime', 'rest', 'tired'])) return _Intent.sleep;
    if (_hasAny(m, ['move', 'activ', 'exercise', 'play', 'running', 'steps'])) {
      return _Intent.activity;
    }
    if (_hasAny(m, ['alert', 'notif', 'warning', 'incident', 'wrong', 'happen'])) {
      return _Intent.alerts;
    }
    if (_hasAny(m, ['where', 'location', 'map', 'safe zone', 'geofence', 'home', 'lost'])) {
      return _Intent.location;
    }
    if (_hasAny(m, ['trend', 'week', 'month', 'pattern', 'improv', 'better', 'worse', 'change'])) {
      return _Intent.trend;
    }
    if (_hasAny(m, ['how is', 'how are', 'doing', 'status', 'overall', 'summary', 'okay', 'ok', 'fine', 'alright'])) {
      return _Intent.overall;
    }
    return _Intent.unknown;
  }

  // ── Reply builders ───────────────────────────────────────────────────────
  String _greetingReply() =>
      "Hi there! 👋 ${s.hasData ? "${_cap(s.childName)} is ${_overallWord()} right now. " : ''}"
      'What would you like to check — heart rate, stress, sleep, or general advice?';

  String _helpReply() =>
      "I'm AEGIS Guard, your on-device helper. I can:\n"
      "• Explain ${s.childName}'s live vitals (heart rate, oxygen, temperature)\n"
      '• Flag stress patterns and when they tend to happen\n'
      '• Summarise how the day or week has gone\n'
      '• Talk through everyday concerns — sleep, anxiety, tantrums, focus and more\n\n'
      'Everything you tell me stays on this phone. What shall we look at?';

  String _overallReply() {
    if (!s.hasData) return _noData();
    final v = s.latest!;
    final r = s.hrRange;
    final hrOk = v.heartRate >= r.low && v.heartRate <= r.high;
    final spo2Ok = v.spo2 >= 95;
    final stress = s.stressCount(_day);
    final parts = <String>[];
    parts.add("Here's how ${_cap(s.childName)} is doing"
        '${s.isLive ? ' right now' : ' (last reading ${_lastAgo()})'}:');
    parts.add('❤️ Heart rate ${v.heartRate} bpm — ${hrOk ? 'normal' : 'a little outside the usual band'} '
        'for age ${s.child?.age ?? 8}.');
    parts.add('🫁 Oxygen ${v.spo2}% — ${spo2Ok ? 'healthy' : 'slightly low, worth watching'}.');
    parts.add('🌡️ Temperature ${v.temperature.toStringAsFixed(1)}°C.');
    parts.add(stress == 0
        ? '😌 No stress alerts in the last 24 hours — a calm day.'
        : '⚠️ $stress stress-related moment${stress == 1 ? '' : 's'} in the last 24 hours.');
    parts.add(stress == 0 && hrOk && spo2Ok
        ? 'Overall: settled and healthy. 💜'
        : 'Nothing alarming, but keep an eye out and ask me for tips if you like.');
    return parts.join('\n');
  }

  String _heartReply() {
    if (!s.hasData) return _noData();
    final v = s.latest!;
    final r = s.hrRange;
    final avg = s.avgHr(_day);
    final peak = s.peakHr(_day);
    final ok = v.heartRate >= r.low && v.heartRate <= r.high;
    final b = StringBuffer();
    b.write("${_cap(s.childName)}'s heart rate is currently ${v.heartRate} bpm. ");
    b.write('For a ${s.child?.age ?? 8}-year-old, a resting rate of ${r.low}–${r.high} bpm '
        'is typical, so this is ${ok ? 'right where it should be ✅' : 'a bit outside that range'}. ');
    if (avg != null) b.write('The 24-hour average is ${avg.toStringAsFixed(0)} bpm. ');
    if (peak != null) {
      b.write('It peaked at ${peak.value.toStringAsFixed(0)} bpm around '
          '${formatHour(peak.at.hour)} — usually that just means activity or excitement. ');
    }
    if (!ok && v.heartRate > r.high) {
      b.write('\n\nIf the rate stays high while they\'re resting, give them a calm moment '
          'and some water; mention it to a doctor if it keeps up.');
    }
    return b.toString();
  }

  String _oxygenReply() {
    if (!s.hasData) return _noData();
    final v = s.latest!;
    final low = s.lowestSpo2(_day);
    final b = StringBuffer();
    b.write("Oxygen (SpO₂) for ${s.childName} is ${v.spo2}%. ");
    if (v.spo2 >= 95) {
      b.write('Anything 95% or above is perfectly healthy, so this looks great 👍 ');
    } else if (v.spo2 >= VitalsSnapshot.spo2Low) {
      b.write('That\'s on the low side of normal — worth a glance but not alarming. ');
    } else {
      b.write('That\'s below the 94% mark where the band raises an alert. '
          'Check that the band is snug, and if it stays low, contact your pediatrician. ');
    }
    if (low != null && low.value < 95) {
      b.write('\n\nThe lowest reading in the last day was ${low.value.toStringAsFixed(0)}% '
          'around ${formatHour(low.at.hour)}.');
    }
    return b.toString();
  }

  String _tempReply() {
    if (!s.hasData) return _noData();
    final v = s.latest!;
    final avg = s.avgTemp(_day);
    final b = StringBuffer();
    b.write("${_cap(s.childName)}'s temperature reads ${v.temperature.toStringAsFixed(1)}°C. ");
    if (v.temperature >= VitalsSnapshot.tempFever) {
      b.write('That\'s in the fever range. Keep them hydrated and rested, dress them '
          'lightly, and check with a doctor if it rises or other symptoms appear. ');
    } else {
      b.write('That\'s within a normal range — no sign of fever. ');
    }
    if (avg != null) {
      b.write('The 24-hour average is ${avg.toStringAsFixed(1)}°C.');
    }
    return b.toString();
  }

  String _stressReply() {
    if (!s.hasData) return _noData();
    final today = s.stressCount(_day);
    final week = s.stressCount(_week);
    final peak = s.stressPeakHour(_week);
    final b = StringBuffer();
    if (today == 0) {
      b.write('Good news — no stress alerts for ${s.childName} in the last 24 hours. 😌 ');
    } else {
      b.write('There ${today == 1 ? 'was' : 'were'} $today stress-related moment'
          '${today == 1 ? '' : 's'} today for ${s.childName}. ');
    }
    b.write('Over the week the total is $week. ');
    if (peak != null && peak.count >= 2) {
      b.write('\n\nThey tend to cluster around ${formatHour(peak.hour)} — a predictable '
          'wind-down routine then (quiet time, a snack, a short chat) often helps. ');
    }
    b.write('\n\nWant some calming techniques you can try together?');
    return b.toString();
  }

  String _sleepReply() {
    // The band doesn't report sleep stages — be honest, then give grounded help.
    final b = StringBuffer();
    b.write("I don't track sleep stages directly yet, so I can't give you sleep hours. ");
    final nightStress = s.alertsWithin(_week)
        .where((a) =>
            (a.type == 'STRESS' || a.type == 'ELEVATED') &&
            (a.timestamp.hour >= 20 || a.timestamp.hour <= 6))
        .length;
    if (nightStress > 0) {
      b.write('I did notice $nightStress evening/night stress moment'
          '${nightStress == 1 ? '' : 's'} this week, which can disrupt rest. ');
    }
    b.write('\n\nFor steadier sleep: keep a consistent bedtime, dim screens an hour '
        'before, and a calm routine (bath, story, lights low). A resting heart rate '
        'that settles in the evening is a good sign they\'re winding down.');
    return b.toString();
  }

  String _activityReply() {
    if (!s.hasData) return _noData();
    final mov = s.avgMovement(_day);
    final b = StringBuffer();
    if (mov == null) {
      b.write("I don't have enough movement data yet today. ");
    } else if (mov < 0.4) {
      b.write('${_cap(s.childName)} has been fairly still today (low movement). '
          'A bit of active play is great for mood and sleep. ');
    } else if (mov < 0.9) {
      b.write('${_cap(s.childName)} has had a nicely balanced, moderately active day. 🙂 ');
    } else {
      b.write('${_cap(s.childName)} has been very active today — lots of movement, which '
          'naturally lifts the heart rate. ');
    }
    b.write('Kids generally benefit from around an hour of active play a day.');
    return b.toString();
  }

  String _alertsReply() {
    final recent = s.alertsWithin(_week);
    if (recent.isEmpty) {
      return 'No alerts for ${s.childName} in the past week — all quiet. 🟢';
    }
    final b = StringBuffer();
    b.write('There ${recent.length == 1 ? 'has' : 'have'} been ${recent.length} alert'
        '${recent.length == 1 ? '' : 's'} this week:\n');
    for (final a in recent.take(4)) {
      b.write('• ${a.typeLabel} — ${formatAgo(s.now.difference(a.timestamp))}'
          '${a.resolved ? ' (resolved)' : ''}\n');
    }
    b.write('\nYou can see the full list with locations on the Alerts tab.');
    return b.toString();
  }

  String _locationReply() {
    final hasZone = s.child?.geofence != null;
    return hasZone
        ? "I keep ${s.childName}'s live position and safe zone on the Map tab. "
            'You\'ll get an alert the moment they leave the safe zone, so no news '
            'there is good news. Open the Map tab to see exactly where they are now.'
        : "You haven't set a safe zone yet. Add one on the Map tab and I'll alert "
            'you whenever ${s.childName} leaves it.';
  }

  String _trendReply() {
    if (!s.hasData) return _noData();
    final avgHrWeek = s.avgHr(_week);
    final hrDelta = s.hrTrend(_week);
    final stressWeek = s.stressCount(_week);
    final peak = s.stressPeakHour(_week);
    final b = StringBuffer();
    b.write("This week for ${_cap(s.childName)}:\n");
    if (avgHrWeek != null) {
      b.write('• Avg heart rate ${avgHrWeek.toStringAsFixed(0)} bpm');
      if (hrDelta != null && hrDelta.abs() >= 3) {
        b.write(' (${hrDelta > 0 ? 'up' : 'down'} ${hrDelta.abs().toStringAsFixed(0)} '
            'vs last week)');
      }
      b.write('\n');
    }
    b.write('• $stressWeek stress moment${stressWeek == 1 ? '' : 's'} logged\n');
    if (peak != null && peak.count >= 2) {
      b.write('• Most common around ${formatHour(peak.hour)}\n');
    }
    b.write('\nThe Trends tab shows all of this on a chart. Overall the week looks '
        '${stressWeek <= 1 ? 'calm and steady 💜' : 'manageable — a calmer routine could smooth out the spikes.'}');
    return b.toString();
  }

  String _adviceReply(String m) {
    final topic = _matchAdviceTopic(m);
    final guidance = _adviceTopics[topic]!;
    final b = StringBuffer();
    b.write(guidance);
    // Tie anxiety/stress topics back to real data when we have it.
    if ((topic == 'anxiety' || topic == 'tantrums' || topic == 'fear') && s.hasData) {
      final peak = s.stressPeakHour(_week);
      if (peak != null && peak.count >= 2) {
        b.write('\n\n📊 From ${s.childName}\'s readings, tense moments often appear around '
            '${formatHour(peak.hour)} — planning ahead for that window can really help.');
      }
    }
    return b.toString();
  }

  String _thanksReply() =>
      "You're very welcome 💜 I'm always here on your phone whenever you want to "
      "check in on ${s.childName}.";

  String _fallbackReply() {
    final name = s.childName;
    return "I want to make sure I help with the right thing. I can talk about "
        "$name's heart rate, oxygen, temperature, stress and activity, summarise "
        'the day or week, or talk through concerns like sleep, anxiety, tantrums, '
        'eating or focus. Try asking one of those — for example, "How is $name '
        'doing today?"';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _overallWord() {
    if (!s.hasData) return 'steady';
    final v = s.latest!;
    final r = s.hrRange;
    final ok = v.heartRate >= r.low && v.heartRate <= r.high && v.spo2 >= 95;
    final calm = s.stressCount(_day) == 0;
    if (ok && calm) return 'calm and healthy';
    if (ok) return 'stable';
    return 'worth a quick look';
  }

  String _lastAgo() =>
      s.sinceLastReading == null ? 'a while ago' : formatAgo(s.sinceLastReading!);

  String _noData() =>
      "I don't have any readings from ${s.childName}'s band yet. Once it's powered "
      'on and connected to WiFi, vitals will flow in and I can give you specifics. '
      'In the meantime, feel free to ask me general child-wellbeing questions.';

  bool _isGreeting(String m) =>
      RegExp(r'^(hi|hey|hello|yo|hiya|good (morning|afternoon|evening))\b').hasMatch(m);

  bool _hasAny(String m, Iterable<String> keys) => keys.any((k) => m.contains(k));

  String _matchAdviceTopic(String m) {
    for (final entry in _adviceKeywords.entries) {
      if (_hasAny(m, entry.value)) return entry.key;
    }
    return 'general';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

enum _Intent {
  greeting,
  help,
  overall,
  heart,
  oxygen,
  temperature,
  stress,
  sleep,
  activity,
  alerts,
  location,
  trend,
  advice,
  thanks,
  unknown,
}

// ── Child-wellbeing knowledge base ──────────────────────────────────────────
// Keyword triggers per topic (checked before the vitals intents).
const Map<String, List<String>> _adviceKeywords = {
  'anxiety': ['anxious', 'anxiety', 'worried', 'worry', 'nervous', 'panic', 'overwhelm'],
  'tantrums': ['tantrum', 'meltdown', 'angry', 'anger', 'acting out', 'misbehav', 'aggress'],
  'fear': ['scared', 'afraid', 'fear', 'nightmare', 'monster', 'dark'],
  'sadness': ['sad', 'crying', 'cry', 'down', 'depress', 'withdrawn', 'lonely'],
  'eating': ['eat', 'eating', 'appetite', 'food', 'hungry', 'picky', 'meal'],
  'focus': ['focus', 'concentrate', 'attention', 'distract', 'hyper', 'restless', 'homework'],
  'screen': ['screen', 'phone time', 'tablet', 'gaming', 'youtube', 'tv time'],
  'bullying': ['bully', 'bullied', 'teasing', 'friends at school', 'left out'],
};

// One topic-matched fallback so the map keys line up with _adviceKeywords.
const Map<String, String> _adviceTopics = {
  'anxiety':
      'When a child feels anxious, naming the feeling helps — "It looks like you\'re '
          'feeling worried, that\'s okay." Try slow "balloon" breathing together (in for '
          '4, out for 6), keep routines predictable, and offer reassurance without '
          'dismissing the worry. Short, regular check-ins work better than one big talk.',
  'tantrums':
      'Tantrums are usually a young brain overwhelmed, not defiance. Stay calm and '
          'close, keep everyone safe, and wait for the storm to pass before talking. '
          'Afterwards, name the feeling and the limit ("You were upset we left the park. '
          'It\'s okay to be upset; it\'s not okay to hit."). Consistency and a predictable '
          'routine reduce how often they happen.',
  'fear':
      'Fears like the dark or nightmares are a normal part of growing up. Validate it '
          '("That sounded scary"), keep a comforting bedtime routine, and a nightlight or '
          'a "brave" soft toy can help. Avoid forcing them to "face it" abruptly — small, '
          'supported steps build confidence.',
  'sadness':
      'If your child seems sad or withdrawn, make space to listen without rushing to '
          'fix it. Keep up connection, sleep, play and gentle routine. Low mood that '
          'lingers for more than a couple of weeks, or affects eating and sleep, is worth '
          'raising with your doctor.',
  'eating':
      'Picky eating is very common. Offer a small portion of new foods alongside '
          'familiar ones, keep mealtimes calm and pressure-free, and let them help '
          'prepare food. Avoid making meals a battle — appetite varies day to day. '
          'Sudden, lasting appetite loss is worth a check-up.',
  'focus':
      'For focus and restlessness, try shorter task chunks with movement breaks, a '
          'tidy distraction-free space, and clear one-step instructions. Plenty of '
          'physical activity and good sleep make a big difference. If it\'s persistent '
          'across home and school, a chat with their teacher or doctor can help.',
  'screen':
      'For screen time, agree clear limits together, keep screens out of the bedroom '
          'and off an hour before bed, and balance with active play and family time. '
          'Co-watching and talking about what they see matters more than the clock alone.',
  'bullying':
      'If you suspect bullying, listen calmly and let them know it\'s not their fault. '
          'Keep notes of what happened, stay in contact with the school, and rebuild '
          'confidence through activities they enjoy. Reassure them you\'re on their side.',
  'general':
      'Happy to talk it through. The basics that help most things: steady routines, '
          'good sleep, active play, and feeling listened to. Tell me a bit more about '
          'what\'s going on and I\'ll give more specific suggestions.',
};
