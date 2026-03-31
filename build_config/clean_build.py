#!/usr/bin/env python3
"""
Word Bloom - Clean Build Script
================================
Cleans all Android build artifacts that cause UID duplicate conflicts
before running Godot export. Run this BEFORE every build.

Usage:
    python clean_build.py          # Clean only
    python clean_build.py --apk    # Clean + build APK
    python clean_build.py --aab    # Clean + build AAB
    python clean_build.py --all    # Clean + build APK + AAB
    python clean_build.py --install # Clean + build APK + install on device
"""

import os
import sys
import shutil
import subprocess
import time

# === Configuration ===
PROJECT_DIR = r"C:\Users\0\ai프로젝트\wordPuzzle_Godot\Puzzle\word-puzzle"
ANDROID_BUILD = os.path.join(PROJECT_DIR, "android", "build")
GODOT_EXE = r"C:\Users\0\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe"
OUTPUT_DIR = r"C:\Users\0\ai프로젝트\wordPuzzle_Godot\build"
ADB_PATH = r"C:\Users\0\AppData\Local\Android\Sdk\platform-tools\adb.exe"
PACKAGE_NAME = "com.wordbloom.game"

# Directories that cause UID conflicts
CLEAN_TARGETS = [
    os.path.join(ANDROID_BUILD, "src", "main", "assets"),
    os.path.join(ANDROID_BUILD, "assetPackInstallTime", "src", "main", "assets"),
    os.path.join(ANDROID_BUILD, "build", "intermediates"),
    os.path.join(ANDROID_BUILD, "build", "outputs"),
    os.path.join(ANDROID_BUILD, "build", "generated"),
]

# Directories that need .gdignore
GDIGNORE_DIRS = [
    os.path.join(ANDROID_BUILD, "build"),
    os.path.join(ANDROID_BUILD, "src", "main", "assets"),
    os.path.join(ANDROID_BUILD, "src", "instrumented"),
    os.path.join(ANDROID_BUILD, ".gradle"),
    os.path.join(ANDROID_BUILD, "assetPackInstallTime", "src", "main", "assets"),
]


def log(msg):
    print(f"[clean_build] {msg}")


def stop_gradle():
    """Stop Gradle daemon to release file locks."""
    log("Stopping Gradle daemon...")
    gradlew = os.path.join(ANDROID_BUILD, "gradlew.bat")
    if os.path.exists(gradlew):
        subprocess.run([gradlew, "--stop"], cwd=ANDROID_BUILD,
                       capture_output=True, timeout=30)


def clean_directory(path):
    """Remove all files in directory except .gdignore."""
    if not os.path.exists(path):
        return
    for item in os.listdir(path):
        if item == ".gdignore":
            continue
        full_path = os.path.join(path, item)
        try:
            if os.path.isdir(full_path):
                shutil.rmtree(full_path)
            else:
                os.remove(full_path)
        except PermissionError:
            log(f"  WARNING: Could not remove {full_path} (locked)")


def ensure_gdignore():
    """Create .gdignore files in all required directories."""
    for dir_path in GDIGNORE_DIRS:
        os.makedirs(dir_path, exist_ok=True)
        gdignore = os.path.join(dir_path, ".gdignore")
        if not os.path.exists(gdignore):
            open(gdignore, "w").close()
            log(f"  Created {gdignore}")


def ensure_local_properties():
    """Ensure local.properties exists with SDK path."""
    lp = os.path.join(ANDROID_BUILD, "local.properties")
    sdk_dir = r"C:\Users\0\AppData\Local\Android\Sdk"
    if not os.path.exists(lp) or "sdk.dir" not in open(lp).read():
        with open(lp, "w") as f:
            f.write(f"sdk.dir={sdk_dir.replace(os.sep, '/')}\n")
        log("  Restored local.properties")


def clean():
    """Full clean of all UID-conflict-causing directories."""
    log("=" * 50)
    log("CLEANING BUILD ARTIFACTS")
    log("=" * 50)

    stop_gradle()

    for target in CLEAN_TARGETS:
        if os.path.exists(target):
            clean_directory(target)
            log(f"  Cleaned: {os.path.relpath(target, ANDROID_BUILD)}")

    ensure_gdignore()
    ensure_local_properties()

    log("Clean complete! No UID conflicts should occur.")
    log("")


def build(build_type):
    """Run Godot export."""
    if build_type == "apk":
        preset = "Android Release (APK)"
        output = os.path.join(OUTPUT_DIR, "apk", "WordBloom-final.apk")
    elif build_type == "aab":
        preset = "Android Release (AAB)"
        output = os.path.join(OUTPUT_DIR, "aab", "WordBloom-release.aab")
    else:
        log(f"Unknown build type: {build_type}")
        return False

    os.makedirs(os.path.dirname(output), exist_ok=True)

    log(f"Building {build_type.upper()}...")
    log(f"  Preset: {preset}")
    log(f"  Output: {output}")

    result = subprocess.run(
        [GODOT_EXE, "--headless", "--path", PROJECT_DIR,
         "--export-release", preset, output],
        capture_output=True, timeout=900,
        encoding="utf-8", errors="replace"
    )

    # Check for UID conflicts in output
    combined = result.stdout + result.stderr
    uid_conflicts = [l for l in combined.split("\n") if "UID duplicate" in l]
    if uid_conflicts:
        log(f"  WARNING: {len(uid_conflicts)} UID conflicts detected!")
        for c in uid_conflicts[:3]:
            log(f"    {c.strip()}")

    if os.path.exists(output):
        size_mb = os.path.getsize(output) / (1024 * 1024)
        log(f"  SUCCESS: {build_type.upper()} built ({size_mb:.1f} MB)")
        return True
    else:
        log(f"  FAILED: {build_type.upper()} build failed")
        # Print last few lines of output for debugging
        for line in combined.split("\n")[-5:]:
            if line.strip():
                log(f"    {line.strip()}")
        return False


def install():
    """Install APK on connected device."""
    apk = os.path.join(OUTPUT_DIR, "apk", "WordBloom-final.apk")
    if not os.path.exists(apk):
        log("No APK found. Build first with --apk")
        return False

    log("Installing APK on device...")

    # Uninstall old version first
    subprocess.run([ADB_PATH, "uninstall", PACKAGE_NAME],
                   capture_output=True, timeout=30)

    result = subprocess.run([ADB_PATH, "install", apk],
                            capture_output=True, text=True, timeout=120)

    if "Success" in result.stdout:
        log("  APK installed successfully!")
        return True
    else:
        log(f"  Install failed: {result.stdout.strip()}")
        return False


def main():
    args = sys.argv[1:]

    if not args:
        clean()
        return

    # Always clean first
    clean()

    if "--apk" in args or "--all" in args:
        build("apk")

    if "--aab" in args or "--all" in args:
        # Clean again after APK build (APK leaves files in assets)
        if "--apk" in args or "--all" in args:
            log("Re-cleaning before AAB build...")
            for target in CLEAN_TARGETS:
                if os.path.exists(target):
                    clean_directory(target)
            ensure_gdignore()
        build("aab")

    if "--install" in args:
        if "--apk" not in args and "--all" not in args:
            build("apk")
        install()


if __name__ == "__main__":
    main()
