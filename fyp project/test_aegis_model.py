# ============================================================
# AEGIS — Fixed Model Verification & Edge Case Testing
# Uses ACTUAL WESAD feature ranges (verified from scaler)
# Run: python test_aegis_model.py
# ============================================================

import joblib
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from sklearn.model_selection import StratifiedKFold, cross_val_score
import warnings
warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────────────────────
# ACTUAL WESAD RANGES (verified from check_ranges.py)
# hr_mean:     mean=74.5,  std=7.3    range: 60-89
# hrv:         mean=184.4, std=42.8   range: 99-270  (ms)
# rmssd:       mean=250.7, std=61.4   range: 128-373 (ms)
# eda_mean:    mean=2.12,  std=2.76   range: 0-7.6   (uS)
# eda_std:     mean=0.071, std=0.10
# eda_max:     mean=2.30,  std=2.91
# eda_slope:   mean=-0.0001, std=0.0013
# spike_count: mean=6.75,  std=3.06   range: 1-13
# temp_mean:   mean=33.1,  std=1.45   WRIST SKIN temp, not core!
# acc_mean:    mean=63.7,  std=0.93   raw ADC units
# acc_max:     mean=98.3,  std=31.3
#
# STRESS key signals vs NORMAL:
# eda_mean rises:   2.12 -> 3.10
# temp_mean drops:  33.1 -> 32.4  (skin cools under stress)
# hr_mean rises:    74.5 -> 78.0  (subtle)
# ─────────────────────────────────────────────────────────────

print("=" * 60)
print("  AEGIS — Model Verification & Edge Case Testing")
print("  (Using real WESAD feature ranges)")
print("=" * 60)

try:
    model  = joblib.load('aegis_model.pkl')
    scaler = joblib.load('aegis_scaler.pkl')
    print("✅ Model loaded successfully\n")
except FileNotFoundError:
    print("❌ ERROR: aegis_model.pkl not found.")
    exit()

FEATURE_NAMES = [
    'hr_mean', 'hrv', 'rmssd',
    'eda_mean', 'eda_std', 'eda_max', 'eda_slope', 'spike_count',
    'temp_mean', 'temp_std', 'temp_slope',
    'acc_mean', 'acc_std', 'acc_max'
]

LABELS = {0: 'NORMAL', 1: 'STRESS'}
pass_count = 0
fail_count = 0

def predict(feature_dict):
    raw    = np.array([[feature_dict.get(f, 0.0) for f in FEATURE_NAMES]])
    scaled = scaler.transform(raw)
    pred   = model.predict(scaled)[0]
    proba  = model.predict_proba(scaled)[0]
    return pred, proba

def run_test(test_name, feature_dict, expected_int, description, danger_level="LOW"):
    global pass_count, fail_count
    pred_int, proba = predict(feature_dict)
    passed = (pred_int == expected_int)
    if passed:
        status = "✅ PASS"
        pass_count += 1
    else:
        status = "❌ FAIL" if danger_level == "LOW" else "🚨 CRITICAL FAIL"
        fail_count += 1
    confidence = proba[pred_int] * 100
    print(f"  {status}  [{danger_level}]  {test_name}")
    print(f"         Expected : {LABELS[expected_int]}")
    print(f"         Got      : {LABELS[pred_int]}  (confidence {confidence:.1f}%)")
    print(f"         Scenario : {description}")
    print()

# ─────────────────────────────────────────────────────────────
# SUITE 1 — NORMAL
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 1: Normal Scenarios")
print("-" * 60 + "\n")

run_test("Resting adult",
    {'hr_mean': 68, 'hrv': 195, 'rmssd': 260,
     'eda_mean': 1.5, 'eda_std': 0.05, 'eda_max': 1.8,
     'eda_slope': -0.0001, 'spike_count': 5,
     'temp_mean': 33.5, 'temp_std': 0.025, 'temp_slope': 0.0,
     'acc_mean': 63.8, 'acc_std': 1.5, 'acc_max': 80},
    0, "All values near WESAD baseline, relaxed", "LOW")

run_test("Calm child sitting",
    {'hr_mean': 72, 'hrv': 180, 'rmssd': 240,
     'eda_mean': 1.8, 'eda_std': 0.04, 'eda_max': 2.0,
     'eda_slope': 0.0, 'spike_count': 6,
     'temp_mean': 33.2, 'temp_std': 0.030, 'temp_slope': 0.0,
     'acc_mean': 63.6, 'acc_std': 1.2, 'acc_max': 75},
    0, "Child sitting calmly, low EDA, stable HR", "LOW")

run_test("Post-meal relaxed",
    {'hr_mean': 76, 'hrv': 170, 'rmssd': 230,
     'eda_mean': 2.0, 'eda_std': 0.06, 'eda_max': 2.2,
     'eda_slope': 0.0001, 'spike_count': 6,
     'temp_mean': 33.8, 'temp_std': 0.035, 'temp_slope': 0.0005,
     'acc_mean': 63.7, 'acc_std': 1.8, 'acc_max': 85},
    0, "After eating, slightly warm, calm HR", "LOW")

# ─────────────────────────────────────────────────────────────
# SUITE 2 — PHYSICAL ACTIVITY
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 2: Physical Activity (must NOT alert)")
print("-" * 60 + "\n")

run_test("Child running (play)",
    {'hr_mean': 85, 'hrv': 155, 'rmssd': 210,
     'eda_mean': 2.5, 'eda_std': 0.07, 'eda_max': 2.9,
     'eda_slope': 0.0005, 'spike_count': 6,
     'temp_mean': 33.9, 'temp_std': 0.05, 'temp_slope': 0.0008,
     'acc_mean': 64.8, 'acc_std': 7.5, 'acc_max': 155},
    0, "High acc, mild HR rise, EDA near baseline", "HIGH")

run_test("Walking fast",
    {'hr_mean': 80, 'hrv': 165, 'rmssd': 225,
     'eda_mean': 2.2, 'eda_std': 0.06, 'eda_max': 2.5,
     'eda_slope': 0.0002, 'spike_count': 6,
     'temp_mean': 33.6, 'temp_std': 0.04, 'temp_slope': 0.0004,
     'acc_mean': 64.2, 'acc_std': 5.0, 'acc_max': 130},
    0, "Moderate movement, no emotional stress markers", "HIGH")

# ─────────────────────────────────────────────────────────────
# SUITE 3 — REAL STRESS
# Key: eda_mean > 3.5, temp_mean drops below 32.5, spikes > 9
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 3: Real Stress (CRITICAL)")
print("-" * 60 + "\n")

run_test("Clear psychological stress",
    {'hr_mean': 82, 'hrv': 175, 'rmssd': 255,
     'eda_mean': 4.2, 'eda_std': 0.09, 'eda_max': 5.1,
     'eda_slope': 0.0010, 'spike_count': 10,
     'temp_mean': 32.2, 'temp_std': 0.040, 'temp_slope': -0.0005,
     'acc_mean': 63.8, 'acc_std': 2.0, 'acc_max': 90},
    1, "High EDA + spikes + skin cooling + low movement", "HIGH")

run_test("Anxiety episode",
    {'hr_mean': 79, 'hrv': 172, 'rmssd': 248,
     'eda_mean': 3.8, 'eda_std': 0.085, 'eda_max': 4.6,
     'eda_slope': 0.0008, 'spike_count': 9,
     'temp_mean': 32.5, 'temp_std': 0.038, 'temp_slope': -0.0004,
     'acc_mean': 63.7, 'acc_std': 2.2, 'acc_max': 92},
    1, "Elevated EDA and spikes, skin temp drops", "HIGH")

run_test("Sustained stress",
    {'hr_mean': 80, 'hrv': 178, 'rmssd': 258,
     'eda_mean': 5.0, 'eda_std': 0.10, 'eda_max': 6.2,
     'eda_slope': 0.0012, 'spike_count': 11,
     'temp_mean': 32.0, 'temp_std': 0.042, 'temp_slope': -0.0006,
     'acc_mean': 63.6, 'acc_std': 1.8, 'acc_max': 85},
    1, "Prolonged stress: very high EDA, cool wrist", "HIGH")

# ─────────────────────────────────────────────────────────────
# SUITE 4 — EDGE CASES
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 4: Tricky Edge Cases")
print("-" * 60 + "\n")

run_test("Happy excitement",
    {'hr_mean': 82, 'hrv': 168, 'rmssd': 235,
     'eda_mean': 2.6, 'eda_std': 0.07, 'eda_max': 3.0,
     'eda_slope': 0.0003, 'spike_count': 7,
     'temp_mean': 33.4, 'temp_std': 0.035, 'temp_slope': 0.0002,
     'acc_mean': 64.1, 'acc_std': 4.0, 'acc_max': 120},
    0, "Excited but happy: warm skin, moderate EDA, active", "MEDIUM")

run_test("Brief startle",
    {'hr_mean': 74, 'hrv': 185, 'rmssd': 252,
     'eda_mean': 2.3, 'eda_std': 0.15, 'eda_max': 3.2,
     'eda_slope': -0.0008, 'spike_count': 7,
     'temp_mean': 33.1, 'temp_std': 0.030, 'temp_slope': 0.0,
     'acc_mean': 63.8, 'acc_std': 2.5, 'acc_max': 100},
    0, "Single startle: avg HR normal, EDA declining", "MEDIUM")

run_test("Hot environment",
    {'hr_mean': 77, 'hrv': 175, 'rmssd': 242,
     'eda_mean': 2.8, 'eda_std': 0.08, 'eda_max': 3.2,
     'eda_slope': 0.0004, 'spike_count': 6,
     'temp_mean': 35.2, 'temp_std': 0.055, 'temp_slope': 0.0009,
     'acc_mean': 63.7, 'acc_std': 1.5, 'acc_max': 82},
    0, "Hot day: WARM skin (not cooling), no spike pattern", "MEDIUM")

# ─────────────────────────────────────────────────────────────
# SUITE 5 — SLEEP
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 5: Sleep (must NEVER alert)")
print("-" * 60 + "\n")

run_test("Deep sleep",
    {'hr_mean': 58, 'hrv': 230, 'rmssd': 320,
     'eda_mean': 0.8, 'eda_std': 0.02, 'eda_max': 0.9,
     'eda_slope': 0.0, 'spike_count': 2,
     'temp_mean': 34.2, 'temp_std': 0.018, 'temp_slope': -0.0001,
     'acc_mean': 63.5, 'acc_std': 0.4, 'acc_max': 66},
    0, "Very low HR, very high HRV, minimal EDA", "HIGH")

run_test("REM sleep",
    {'hr_mean': 63, 'hrv': 215, 'rmssd': 298,
     'eda_mean': 1.1, 'eda_std': 0.03, 'eda_max': 1.3,
     'eda_slope': 0.0001, 'spike_count': 3,
     'temp_mean': 34.0, 'temp_std': 0.022, 'temp_slope': 0.0,
     'acc_mean': 63.5, 'acc_std': 0.8, 'acc_max': 70},
    0, "REM: slight HR variability, very low EDA", "HIGH")

# ─────────────────────────────────────────────────────────────
# SUITE 6 — SENSOR VALIDITY
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 6: Sensor Validity Detection")
print("-" * 60 + "\n")

def check_sensor_validity(hr, temp, gsr, acc_mean):
    if hr < 40 or hr > 220:
        return False, f"HR={hr} out of range (40-220)"
    if temp < 25.0 or temp > 40.0:
        return False, f"Temp={temp} not wrist skin temp (25-40)"
    if gsr < 0.0 or gsr > 50.0:
        return False, f"GSR={gsr} impossible value"
    if acc_mean < 55 or acc_mean > 75:
        return False, f"ACC={acc_mean} sensor malfunction"
    return True, "OK"

sensor_tests = [
    ("Sensor disconnected",  0,    20.0, 0.0, 63.7, False),
    ("Band not worn",        0,    22.5, 0.0, 63.7, False),
    ("HR sensor fault",      250,  33.0, 2.0, 63.7, False),
    ("Temperature glitch",   72,   15.0, 1.8, 63.7, False),
    ("ACC malfunction",      72,   33.0, 1.8, 10.0, False),
    ("All sensors normal",   74,   33.1, 2.1, 63.7, True),
]

for name, hr, temp, gsr, acc, expect_valid in sensor_tests:
    valid, reason = check_sensor_validity(hr, temp, gsr, acc)
    status = "✅ PASS" if valid == expect_valid else "❌ FAIL"
    tag = "valid" if valid else f"INVALID ({reason})"
    print(f"  {status}  {name}")
    print(f"         Reading : HR={hr}, Temp={temp}, GSR={gsr}, ACC={acc}")
    print(f"         Result  : {tag}")
    print()
    if valid == expect_valid:
        pass_count += 1
    else:
        fail_count += 1

# ─────────────────────────────────────────────────────────────
# SUITE 7 — FLOAT32
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 7: Float32 Precision (simulates ESP32)")
print("-" * 60 + "\n")

tv = np.array([
    [68, 195, 260, 1.5,  0.05, 1.8,  -0.0001, 5,  33.5, 0.025, 0.0,    63.8, 1.5, 80],
    [82, 175, 255, 4.2,  0.09, 5.1,   0.0010, 10, 32.2, 0.040, -0.0005, 63.8, 2.0, 90],
    [58, 230, 320, 0.8,  0.02, 0.9,   0.0,    2,  34.2, 0.018, -0.0001, 63.5, 0.4, 66],
    [80, 178, 258, 5.0,  0.10, 6.2,   0.0012, 11, 32.0, 0.042, -0.0006, 63.6, 1.8, 85],
])
p64   = model.predict(scaler.transform(tv))
p32   = model.predict(scaler.transform(tv.astype(np.float32)))
match = np.sum(p64 == p32)
total = len(p64)
print(f"  Predictions match: {match}/{total}")
if match == total:
    print("  ✅ PASS — Float32 identical to float64")
    pass_count += 1
else:
    print(f"  ⚠️  WARNING — {total-match} differ on float32")
    fail_count += 1
print()

# ─────────────────────────────────────────────────────────────
# SUITE 8 — CROSS VALIDATION with realistic distributions
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 8: Cross Validation Stability")
print("-" * 60 + "\n")

np.random.seed(42)
n = 600
X_n = np.random.normal(
    [74.5,184.4,250.7,2.12,0.071,2.30,-0.0001,6.75,33.1,0.034,0.0,63.7,3.07,98.3],
    [7.3,42.8,61.4,2.76,0.10,2.91,0.0013,3.06,1.45,0.027,0.0006,0.93,2.97,31.3],
    size=(n,14))
X_s = np.random.normal(
    [78.0,188.1,264.2,3.10,0.073,2.78,0.0002,6.89,32.4,0.032,-0.0001,63.7,3.27,99.6],
    [5.8,43.4,58.3,2.17,0.10,2.76,0.0013,3.07,1.06,0.025,0.0005,1.00,3.11,32.3],
    size=(n,14))
X_cv = scaler.transform(np.vstack([X_n, X_s]))
y_cv = np.array([0]*n + [1]*n)
cv   = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X_cv, y_cv, cv=cv, scoring='recall_weighted')
print(f"  CV Scores: {[f'{s*100:.1f}%' for s in scores]}")
print(f"  Mean:      {scores.mean()*100:.2f}%")
print(f"  Std Dev:   {scores.std()*100:.2f}%")
cv_stable = scores.std() < 0.05
if cv_stable:
    print("  ✅ PASS — Model is stable across folds")
    pass_count += 1
else:
    print("  ⚠️  High variance across folds")
    fail_count += 1
print()

# ─────────────────────────────────────────────────────────────
# SUITE 9 — FEATURE IMPORTANCE
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  TEST SUITE 9: Feature Importance Sanity Check")
print("-" * 60 + "\n")

importances = model.feature_importances_
top3_idx    = np.argsort(importances)[::-1][:3]
top3_names  = [FEATURE_NAMES[i] for i in top3_idx]
physio_set  = {'hr_mean','hrv','rmssd','eda_mean','eda_std',
               'eda_max','eda_slope','spike_count','temp_mean'}
overlap     = set(top3_names) & physio_set
print(f"  Top 3 features: {top3_names}")
if len(overlap) >= 2:
    print(f"  ✅ PASS — Physiological features dominate ({overlap})")
    pass_count += 1
else:
    print(f"  ❌ FAIL — Wrong features dominating")
    fail_count += 1
print()

# ─────────────────────────────────────────────────────────────
# VISUAL REPORT
# ─────────────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("  Generating Visual Report...")
print("-" * 60 + "\n")

fig, axes = plt.subplots(1, 3, figsize=(18, 5))
fig.suptitle('AEGIS — Verification Report (Real WESAD Ranges)', fontsize=14)

ax1 = axes[0]
bars = ax1.bar(['Passed','Failed'], [pass_count, fail_count],
               color=['#2ecc71','#e74c3c'], width=0.5)
for bar, c in zip(bars, [pass_count, fail_count]):
    ax1.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.1,
             str(c), ha='center', fontsize=14, fontweight='bold')
ax1.set_title('Test Results')
ax1.set_ylim(0, max(pass_count, fail_count)+4)

ax2 = axes[1]
si  = np.argsort(importances)
ci  = ['#e74c3c' if FEATURE_NAMES[i] in physio_set else '#3498db' for i in si]
ax2.barh([FEATURE_NAMES[i] for i in si], importances[si], color=ci)
ax2.set_title('Feature Importances')
ax2.legend(handles=[
    mpatches.Patch(color='#e74c3c', label='Physio'),
    mpatches.Patch(color='#3498db', label='Movement')], fontsize=8)

ax3 = axes[2]
ax3.plot(range(1,6), scores*100, 'o-', color='#9b59b6', linewidth=2, markersize=8)
ax3.axhline(scores.mean()*100, color='#2ecc71', linestyle='--',
            label=f'Mean {scores.mean()*100:.1f}%')
ax3.axhline(75, color='#e74c3c', linestyle=':', label='Min 75%')
ax3.fill_between(range(1,6),
    (scores.mean()-scores.std())*100, (scores.mean()+scores.std())*100,
    alpha=0.2, color='#9b59b6')
ax3.set_title('CV Stability')
ax3.set_ylim(50, 100)
ax3.legend(fontsize=8)

plt.tight_layout()
plt.savefig('aegis_test_report.png', dpi=150, bbox_inches='tight')
plt.show()
print("  Report saved: aegis_test_report.png\n")

# ─────────────────────────────────────────────────────────────
# FINAL VERDICT
# ─────────────────────────────────────────────────────────────
total_tests = pass_count + fail_count
pass_rate   = (pass_count / total_tests * 100) if total_tests > 0 else 0

print("=" * 60)
print("  FINAL VERDICT")
print("=" * 60 + "\n")
print(f"  Tests passed: {pass_count}/{total_tests} ({pass_rate:.1f}%)")
print()
print("  KEY INSIGHT:")
print("  WESAD stress signals are subtle by nature:")
print("  eda_mean: 2.12 (normal) vs 3.10 (stress) — only 1 uS gap")
print("  temp:     33.1 (normal) vs 32.4 (stress) — only 0.7 C drop")
print("  The Z-score baseline on ESP32 amplifies these differences")
print("  per child, which is where real accuracy improvement comes from.")
print()

if pass_rate >= 80 and fail_count == 0:
    print("  🎉 MODEL READY FOR ESP32 DEPLOYMENT")
    print("     Run convert_to_header.py to generate aegis_model.h")
elif fail_count == 0:
    print("  ✅ ALL TESTS PASSED")
    print("     Run convert_to_header.py next.")
else:
    print("  🚨 SOME TESTS FAILED — review output above")
print("=" * 60)