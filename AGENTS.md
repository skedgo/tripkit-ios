# AGENTS.md

Guidance for coding agents (Claude Code, Codex, …) when working in this repository.

## Tests

- Run the package tests (TripKitTests and TripKitUITests) through the SwiftPM workspace: `xcodebuild test -workspace .swiftpm/xcode/package.xcworkspace -scheme TripKit-Package -destination 'platform=iOS Simulator,name=<installed device>'`.
- Tests that call the live API read `TRIPGO_API_KEY` from the environment and skip without it.

## Running TripKitUIExample

`Examples/TripKitUIExample` exercises TripKitUI changes in a simulator without building the full TripGo app. Two things block a plain build-and-run:

1. **It needs a `TRIPGO_API_KEY` env var.** `AppDelegate` hits a `preconditionFailure` without one, and the shared scheme doesn't set it. For UI-only work a dummy value is enough (Apple's geocoder still returns autocompletion results, so the home card search works): `SIMCTL_CHILD_TRIPGO_API_KEY=dummy xcrun simctl launch <udid> com.skedgo.TripKitUIExample`.
2. **The app target doesn't embed `TripKitAPI.framework`**, so it dies at launch with dyld `Library not loaded: @rpath/TripKitAPI.framework/TripKitAPI`. Copy the framework from the build products into `TripKitUIExample.app/Frameworks/`, re-sign both with `codesign --force --sign -`, then reinstall. `TripKit`, `TripKitUI` and `TripKitInterApp` are embedded correctly.
