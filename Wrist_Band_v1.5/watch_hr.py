# Live HR / IR monitor for the AEGIS band.
# Run:  python watch_hr.py
# Move your finger until IR is HIGH (>40000), then HOLD STILL ~15s and HR appears.
import serial, re, sys, time

PORT = "COM8"
s = serial.Serial(PORT, 115200, timeout=1)
s.setDTR(False); s.setRTS(False)
print("Live monitor on", PORT, "- press Ctrl+C to stop.\n")
print("Move finger until you see IR HIGH, then hold still.\n")

last_hr = None
while True:
    try:
        line = s.readline().decode("utf-8", "replace").strip()
    except Exception:
        continue
    m = re.search(r"IR_RAW:\s*(-?\d+)", line)
    if m:
        ir = int(m.group(1))
        if ir > 40000:
            bar = "FINGER GOOD  >>>>>>>>"
        elif ir > 7000:
            bar = "weak - press more"
        else:
            bar = "NO finger / off spot"
        print(f"IR = {ir:>7}   {bar}")
    h = re.search(r"hr_mean\s*:\s*([0-9.]+)", line)
    if h:
        hr = float(h.group(1))
        if hr > 0:
            print(f"  >>> HEART RATE = {hr:.0f} bpm  <<<")
