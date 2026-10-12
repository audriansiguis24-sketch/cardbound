# Cardbound — Battle Prototype

A small Godot 4 project for the first playable battle-system prototype of an original GBA-inspired card RPG.

## What's included
- Fixed-layout battle screen with player and Ember Wolf HP/shields
- Shuffled 10-card starter deck, 5-card hand, draw/discard piles
- 3 energy each turn
- Attack, defense, draw, heal, and one-use consumable cards
- Vanguard compatibility bonus, enemy turns, run chance, victory/defeat and restart
- Placeholder UI; no final pixel art yet

## Android APK cloud build
This repository includes `.github/workflows/android-apk.yml`. Once uploaded to a GitHub repository:

1. Open the repository on GitHub.
2. Open **Actions** and enable workflows if GitHub asks.
3. Choose **Build Cardbound Android APK** and tap **Run workflow** (or wait for a push build).
4. Open the completed run and download the artifact named by the workflow, then extract the APK from the ZIP.

The APK is a debug/test build, not a Play Store release. The first build may fail if the pinned Godot export action or project preset needs adjustment; check the Actions log before treating it as complete.

## Test locally on Android
Install Godot 4 Android editor from https://godotengine.org/download/android/, extract the project ZIP, then import/open the folder containing `project.godot`.

## Controls
Tap a card to play it. End Turn lets the Ember Wolf attack, and Run attempts to escape. Restart appears when combat ends.
