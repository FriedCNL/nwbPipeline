#!/usr/bin/env python3

import os
import re

def clean_path(path: str) -> str:
    return path.strip().strip('"').strip("'")

def main():
    raw_input = input("Enter the full path to the folder (or press Enter for current directory): ")
    folder = clean_path(raw_input) or os.getcwd()

    print("Checking directory: {}".format(folder))
    if not os.path.isdir(folder):
        print("❌ Not a valid directory.")
        return

    files = os.listdir(folder)
    file_set = set(files)

    spikes_pattern = re.compile(r"^(.+)_spikes\.mat$")
    spikes_files = [f for f in files if spikes_pattern.match(f)]
    print(f"🔍 Found {len(spikes_files)} spikes.mat file(s).")

    if not spikes_files:
        print("⚠️ No spikes.mat files found. Exiting.")
        return

    # Now check for corresponding times files
    missing_times = []
    times_found = 0

    for f in spikes_files:
        base = spikes_pattern.match(f).group(1)
        expected_times = f"times_{base}.mat"
        if expected_times in file_set:
            times_found += 1
        else:
            missing_times.append(expected_times)

    print(f"📁 Found {times_found} matching times.mat file(s).")

    if missing_times:
        print("❗ Missing times_*.mat files:")
        for f in sorted(missing_times):
            print("  {}".format(f))
    else:
        print("✅ All times_*.mat files are present.")

if __name__ == "__main__":
    main()