import joblib
import numpy as np

model  = joblib.load('aegis_model.pkl')
scaler = joblib.load('aegis_scaler.pkl')

FEATURE_NAMES = [
    'hr_mean', 'hrv', 'rmssd',
    'eda_mean', 'eda_std', 'eda_max', 'eda_slope', 'spike_count',
    'temp_mean', 'temp_std', 'temp_slope',
    'acc_mean', 'acc_std', 'acc_max'
]

print("=" * 60)
print("  WESAD Actual Feature Ranges (from your trained scaler)")
print("=" * 60)
print(f"\n{'Feature':<15} {'Mean':>10} {'Std Dev':>10}  {'Typical Range'}")
print("-" * 60)

for i, name in enumerate(FEATURE_NAMES):
    mean = scaler.mean_[i]
    std  = scaler.scale_[i]
    low  = mean - 2*std
    high = mean + 2*std
    print(f"{name:<15} {mean:>10.4f} {std:>10.4f}  [{low:.4f}  to  {high:.4f}]")

print("\n" + "=" * 60)
print("  What STRESS looks like in YOUR training data")
print("=" * 60)

# Use the decision trees to find what feature values lead to STRESS
# Sample 1000 random points around the mean and find which ones predict stress
np.random.seed(42)
samples = np.random.normal(
    loc=scaler.mean_,
    scale=scaler.scale_,
    size=(5000, 14)
)

stress_samples = []
for s in samples:
    scaled = scaler.transform(s.reshape(1, -1))
    pred   = model.predict(scaled)[0]
    if pred == 1:
        stress_samples.append(s)

if stress_samples:
    stress_arr = np.array(stress_samples)
    print(f"\n  Found {len(stress_samples)} stress-classified samples")
    print(f"\n{'Feature':<15} {'Stress Mean':>12} {'Stress Std':>12}")
    print("-" * 45)
    for i, name in enumerate(FEATURE_NAMES):
        print(f"{name:<15} {stress_arr[:,i].mean():>12.4f} {stress_arr[:,i].std():>12.4f}")
else:
    print("  No stress samples found in random sampling.")
    print("  Model may be biased toward NORMAL.")

print("\n" + "=" * 60)
print("  Use these ranges to write realistic test cases!")
print("=" * 60)