# CLAUDE.md

Notes for Claude Code and other AI coding agents working in this repo.
For project overview, architecture, and build commands, see [README](README.md).

## Conventions to preserve

- **Swift 6 strict concurrency.** ViewModels are `@MainActor @Observable`; service types must be `Sendable` or main-actor-isolated.
- **No external dependencies.** Apple frameworks only — do not add SPM, CocoaPods, or Carthage.
- **HA token lives in Keychain** via `KeychainService`, never in SwiftData or `UserDefaults`.
- **Async/await throughout.** No completion handlers.
- **Custom errors** conform to `LocalizedError` (`NFCError`, `HAError`, `KeychainError`).

## File layout

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` — files added to or moved within `AquaTag/` are auto-discovered. Do not hand-edit `project.pbxproj` for routine file moves.
