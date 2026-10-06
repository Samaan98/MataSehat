# Working on MataSehat

Native SwiftUI macOS app. Keep the minimum deployment target at macOS 26.5 and use standard Apple controls and system colors.

## Verification without interrupting the user

- Default to targeted Swift Testing checks for changed logic, persistence, and scheduling. Use builds when compilation needs verification.
- Do not routinely run `MataSehatUITests`, launch the app for manual inspection, or run tests that display native windows. These can take over the user's desktop.
- `MataSehatTests/OverlayWindowTests` displays real AppKit panels. Exclude it from routine noninteractive runs along with the UI test target. The standard command is documented in docs/development.md (linked from README.md).
- Run interactive verification only when an affected behavior cannot be established through noninteractive checks: changed controls or navigation, keyboard/focus behavior, window presentation, or a reproducible UI defect. Select only the relevant scenarios, explain why desktop interaction is needed before starting, and coordinate timing if the user is actively using the desktop.
- Reuse successful verification for the same source tree or commit. A commit, push, documentation edit, or fast-forward merge to an already tested commit does not justify another UI run.
- After a test failure, inspect the failure before retrying. Do not repeatedly rerun UI tests because focus, accessibility authorization, or another application interrupted them. Report such limits accurately.
- Documentation-only changes need a diff check, not application tests. Do not invent a new test requirement just to complete a commit or push.
- These preferences apply to automated XCTest desktop actions and manual computer-use checks alike. Explicit user requests for a particular verification take precedence.
