import pickle
import numpy as np
import pandas as pd
from scipy import signal
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import os

# ─────────────────────────────────────────────
# STEP 1: LOAD WESAD DATA
# ─────────────────────────────────────────────

import os
import pickle

def load_subject(filepath):
    """Load one subject's pkl file"""
    with open(filepath, 'rb') as f:
        data = pickle.load(f, encoding='latin1')
    return data


def load_all_subjects(base_path):
    """Load all subjects"""
    all_data = []
    subject_ids = ['S2','S3','S4','S5','S6','S7','S8','S9',
                   'S10','S11','S12','S13','S14','S15','S16','S17']
    
    for sid in subject_ids:
        filepath = os.path.join(base_path, sid, f'{sid}.pkl')
        
        if os.path.exists(filepath):
            data = load_subject(filepath)
            all_data.append(data)
            print(f"Loaded {sid}")
        else:
            print(f"Missing {sid} — skipping")
    
    return all_data

# ─────────────────────────────────────────────
# STEP 2: EXTRACT FEATURES
# ─────────────────────────────────────────────

# Sampling rates in WESAD wrist sensors
BVP_RATE  = 64   # Hz
EDA_RATE  = 4    # Hz
TEMP_RATE = 4    # Hz
ACC_RATE  = 32   # Hz
LABEL_RATE = 700 # Hz (labels are very high frequency)

WINDOW_SIZE = 60  # seconds per window
STEP_SIZE   = 30  # overlap (seconds)

def extract_hr_features(bvp_window, fs=64):
    """Extract heart rate features from BVP signal"""
    
    # Find peaks (heartbeats) in BVP signal
    peaks, _ = signal.find_peaks(bvp_window, distance=fs*0.5)
    
    if len(peaks) < 2:
        return [0, 0, 0]  # not enough data
    
    # RR intervals (time between beats)
    rr_intervals = np.diff(peaks) / fs * 1000  # in milliseconds
    
    # Heart Rate
    hr_mean = 60000 / np.mean(rr_intervals)    # beats per minute
    
    # Heart Rate Variability (HRV) — very important for stress
    hrv = np.std(rr_intervals)
    
    # RMSSD (another HRV measure)
    rmssd = np.sqrt(np.mean(np.diff(rr_intervals)**2))
    
    return [hr_mean, hrv, rmssd]

def extract_eda_features(eda_window):
    """Extract GSR/EDA features"""
    
    eda_mean  = np.mean(eda_window)
    eda_std   = np.std(eda_window)
    eda_max   = np.max(eda_window)
    eda_slope = np.polyfit(range(len(eda_window)), eda_window, 1)[0]
    
    # Count spikes (sudden rises in GSR = emotional response)
    eda_diff  = np.diff(eda_window)
    spike_count = np.sum(eda_diff > np.std(eda_diff) * 2)
    
    return [eda_mean, eda_std, eda_max, eda_slope, spike_count]

def extract_temp_features(temp_window):
    """Extract temperature features"""
    
    temp_mean  = np.mean(temp_window)
    temp_std   = np.std(temp_window)
    temp_slope = np.polyfit(range(len(temp_window)), temp_window, 1)[0]
    
    return [temp_mean, temp_std, temp_slope]

def extract_acc_features(acc_window):
    """Extract movement features from accelerometer"""
    
    # acc_window shape: (samples, 3) for x, y, z
    magnitude = np.sqrt(
        acc_window[:,0]**2 + 
        acc_window[:,1]**2 + 
        acc_window[:,2]**2
    )
    
    acc_mean = np.mean(magnitude)
    acc_std  = np.std(magnitude)
    acc_max  = np.max(magnitude)
    
    return [acc_mean, acc_std, acc_max]

def get_window_label(label_window):
    """Get majority label for a window"""
    # Only use labels 1 (baseline/normal) and 2 (stress)
    # Ignore 0 (transient), 3 (amusement), 4 (meditation)
    
    values, counts = np.unique(label_window, return_counts=True)
    
    # Find most common label
    sorted_idx = np.argsort(-counts)
    for idx in sorted_idx:
        if values[idx] in [1, 2]:
            return values[idx]
    
    return None  # skip this window

def process_subject(subject_data):
    """Process one subject and return features + labels"""
    
    wrist  = subject_data['signal']['wrist']
    labels = subject_data['label']
    
    bvp  = wrist['BVP'].flatten()
    eda  = wrist['EDA'].flatten()
    temp = wrist['TEMP'].flatten()
    acc  = wrist['ACC']  # shape: (samples, 3)
    
    features_list = []
    labels_list   = []
    
    # Use EDA timing as base (4 Hz = slowest sensor)
    window_samples = WINDOW_SIZE * EDA_RATE  # 60 * 4 = 240
    step_samples   = STEP_SIZE * EDA_RATE    # 30 * 4 = 120
    
    total_windows = (len(eda) - window_samples) // step_samples
    
    for w in range(total_windows):
        
        start_eda = w * step_samples
        end_eda   = start_eda + window_samples
        
        # Scale indices for higher-rate sensors
        start_bvp = int(start_eda * BVP_RATE / EDA_RATE)
        end_bvp   = int(end_eda   * BVP_RATE / EDA_RATE)
        
        start_acc = int(start_eda * ACC_RATE / EDA_RATE)
        end_acc   = int(end_eda   * ACC_RATE / EDA_RATE)
        
        start_lbl = int(start_eda * LABEL_RATE / EDA_RATE)
        end_lbl   = int(end_eda   * LABEL_RATE / EDA_RATE)
        
        # Safety check
        if (end_bvp >= len(bvp) or end_eda >= len(eda) or 
            end_acc >= len(acc) or end_lbl >= len(labels)):
            break
        
        # Get windows
        bvp_win  = bvp[start_bvp:end_bvp]
        eda_win  = eda[start_eda:end_eda]
        temp_win = temp[start_eda:end_eda]
        acc_win  = acc[start_acc:end_acc]
        lbl_win  = labels[start_lbl:end_lbl]
        
        # Get label for this window
        label = get_window_label(lbl_win)
        if label is None:
            continue
        
        # Extract features
        hr_feats   = extract_hr_features(bvp_win)
        eda_feats  = extract_eda_features(eda_win)
        temp_feats = extract_temp_features(temp_win)
        acc_feats  = extract_acc_features(acc_win)
        
        all_features = hr_feats + eda_feats + temp_feats + acc_feats
        
        features_list.append(all_features)
        
        # Convert labels: 1=baseline → 0=NORMAL, 2=stress → 1=STRESS
        labels_list.append(0 if label == 1 else 1)
    
    return features_list, labels_list

# ─────────────────────────────────────────────
# STEP 3: BUILD DATASET FROM ALL SUBJECTS
# ─────────────────────────────────────────────

def build_dataset(wesad_folder):
    """Process all subjects and combine into one dataset"""
    
    all_subjects = load_all_subjects(wesad_folder)
    
    X_all = []
    y_all = []
    
    for i, subject in enumerate(all_subjects):
        print(f"Processing subject {i+2}...")
        features, labels = process_subject(subject)
        X_all.extend(features)
        y_all.extend(labels)
    
    X = np.array(X_all)
    y = np.array(y_all)
    
    print(f"\nDataset built:")
    print(f"Total samples: {len(X)}")
    print(f"Normal samples: {np.sum(y==0)}")
    print(f"Stress samples: {np.sum(y==1)}")
    
    return X, y

# ─────────────────────────────────────────────
# STEP 4: TRAIN THE MODEL
# ─────────────────────────────────────────────

def train_model(X, y):
    """Train and evaluate the model"""
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled  = scaler.transform(X_test)
    
    # Train Random Forest
    # Small size because it will run on ESP32
    model = RandomForestClassifier(
        n_estimators=15,        # 15 trees (small enough for ESP32)
        max_depth=8,            # not too deep
        min_samples_split=10,
        class_weight='balanced',# handles imbalanced data
        random_state=42
    )
    
    print("Training model...")
    model.fit(X_train_scaled, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test_scaled)
    accuracy = np.mean(y_pred == y_test)
    
    print(f"\n{'='*40}")
    print(f"TEST ACCURACY: {accuracy*100:.2f}%")
    print(f"{'='*40}")
    print("\nDetailed Report:")
    print(classification_report(y_test, y_pred, 
                                target_names=['Normal', 'Stress']))
    
    # Cross validation
    cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=5)
    print(f"Cross-validation: {cv_scores.mean()*100:.2f}% ± {cv_scores.std()*100:.2f}%")
    
    # Confusion matrix
    plot_confusion_matrix(y_test, y_pred)
    
    return model, scaler, accuracy

def plot_confusion_matrix(y_test, y_pred):
    """Visualize results"""
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d',
                xticklabels=['Normal', 'Stress'],
                yticklabels=['Normal', 'Stress'])
    plt.title('AEGIS Model — Confusion Matrix')
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.savefig('confusion_matrix.png')
    plt.show()
    print("Confusion matrix saved!")

# ─────────────────────────────────────────────
# STEP 5: SAVE MODEL
# ─────────────────────────────────────────────

def save_model(model, scaler):
    """Save model and scaler"""
    joblib.dump(model,  'aegis_model.pkl')
    joblib.dump(scaler, 'aegis_scaler.pkl')
    print("Model saved: aegis_model.pkl")
    print("Scaler saved: aegis_scaler.pkl")

# ─────────────────────────────────────────────
# STEP 6: CONVERT TO C CODE FOR ESP32
# ─────────────────────────────────────────────

def convert_to_c_header(model, scaler):
    """Convert model to C header file for ESP32"""
    
    # Save scaler values as C constants
    means = scaler.mean_
    stds  = scaler.scale_
    
    c_code = """// aegis_model.h
// Auto-generated — DO NOT EDIT
// AEGIS Stress Detection Model
// Trained on WESAD Dataset

#ifndef AEGIS_MODEL_H
#define AEGIS_MODEL_H

#include <math.h>

// ── Scaler values (from StandardScaler) ──
"""
    
    # Write scaler means
    c_code += f"const float SCALER_MEANS[{len(means)}] = {{"
    c_code += ", ".join([f"{m:.6f}" for m in means])
    c_code += "};\n\n"
    
    # Write scaler stds
    c_code += f"const float SCALER_STDS[{len(stds)}] = {{"
    c_code += ", ".join([f"{s:.6f}" for s in stds])
    c_code += "};\n\n"
    
    # Write feature names as comments
    c_code += """// ── Feature order ──
// [0] hr_mean      [1] hrv         [2] rmssd
// [3] eda_mean     [4] eda_std     [5] eda_max
// [6] eda_slope    [7] spike_count
// [8] temp_mean    [9] temp_std    [10] temp_slope
// [11] acc_mean    [12] acc_std    [13] acc_max

// ── Scale one feature ──
float scaleFeature(float value, int idx) {
    return (value - SCALER_MEANS[idx]) / SCALER_STDS[idx];
}

"""
    
    # Extract and write decision trees
    c_code += "// ── Decision Trees ──\n"
    
    for i, tree in enumerate(model.estimators_):
        c_code += f"\nint tree_{i}(float* f) {{\n"
        c_code += extract_tree_code(tree, indent=4)
        c_code += "}\n"
    
    # Write voting function
    c_code += f"""
// ── Final Prediction (majority vote) ──
// Returns: 0 = NORMAL, 1 = STRESS
int aegis_predict(float* raw_features) {{
    
    // Scale features
    float f[14];
    for (int i = 0; i < 14; i++) {{
        f[i] = scaleFeature(raw_features[i], i);
    }}
    
    // Collect votes from all trees
    int votes = 0;
    int n_trees = {len(model.estimators_)};
    
"""
    
    for i in range(len(model.estimators_)):
        c_code += f"    votes += tree_{i}(f);\n"
    
    c_code += f"""
    // Majority vote
    return (votes > n_trees / 2) ? 1 : 0;
}}

#endif // AEGIS_MODEL_H
"""
    
    with open('aegis_model.h', 'w', encoding='utf-8') as f:
        f.write(c_code)

    print("C header saved: aegis_model.h")
    print("Ready to copy into ESP32 project!")

def extract_tree_code(tree, indent=4):
    """Convert sklearn decision tree to C if/else code"""
    tree_ = tree.tree_
    code = ""
    
    def recurse(node, depth):
        nonlocal code
        pad = " " * (indent + depth * 4)
        
        if tree_.feature[node] != -2:  # not leaf
            feat = tree_.feature[node]
            thresh = tree_.threshold[node]
            code += f"{pad}if (f[{feat}] <= {thresh:.6f}) {{\n"
            recurse(tree_.children_left[node], depth + 1)
            code += f"{pad}}} else {{\n"
            recurse(tree_.children_right[node], depth + 1)
            code += f"{pad}}}\n"
        else:
            # Leaf node — return predicted class
            value = tree_.value[node][0]
            predicted = np.argmax(value)
            code += f"{pad}return {predicted};\n"
    
    recurse(0, 0)
    return code

# ─────────────────────────────────────────────
# MAIN — RUN EVERYTHING
# ─────────────────────────────────────────────

if __name__ == "__main__":
    
    # ← Change this to your WESAD folder path
    WESAD_FOLDER = "E:/WESAD"
    
    print("=" * 50)
    print("AEGIS — WESAD Model Training Pipeline")
    print("=" * 50)
    
    # 1. Build dataset
    X, y = build_dataset(WESAD_FOLDER)
    
    # 2. Train model
    model, scaler, accuracy = train_model(X, y)
    
    # 3. Save
    save_model(model, scaler)
    
    # 4. Convert to C
    convert_to_c_header(model, scaler)
    
    print("\n" + "=" * 50)
    print("DONE! Files created:")
    print("  aegis_model.pkl    → backup")
    print("  aegis_scaler.pkl   → backup")
    print("  aegis_model.h      → copy to ESP32 project")
    print("  confusion_matrix.png → check your accuracy")
    print("=" * 50)