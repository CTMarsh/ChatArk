# ChatArk — pointer

**Full ChatArk rules, architecture and gotchas: `../CLAUDE.md` (Chat-App-Clients).** Estate-wide rules (MR flow, never merge, `gitlab` remote): `../../CLAUDE.md`. Shared iOS/TestFlight/ASC-API lessons: `../../bridge/CLAUDE.md`. This file only adds what is true of this repo; do not duplicate the parent here.

- GitLab `homelab/chatark` (id **40**), default `main`, remote `gitlab`; GitLab push-mirrors to GitHub `CTMarsh/ChatArk` — the local `origin` remote IS GitHub: **never push to `origin`**.
- Native Swift 6 client of the Chat web app (`homelab/chat-app`, id 39) — **feature and Constellation styling parity with it are mandatory**; backend (schema/RPC/Edge Function) changes need both clients updated. **Never weaken RLS, never bypass MFA (AAL2), always validate server-side.** Dev Supabase is the source of truth — prod MUST match dev. RLS helpers `is_conversation_participant()`, `is_workspace_member()`, `is_workspace_admin()`, `is_platform_admin()`: never rename/remove.
- Targets: ChatArk `com.chrismarsh.chatark` (iOS 27.1 / macOS 27 / watchOS 27) + `.share`, `.notification-service`, `.ChatWidgets`, `.watchos`, ChatWatchComplication, tests.
- `project.yml` (XcodeGen) is the source of truth; CI runs `xcodegen generate`. `ChatArk.xcodeproj` is also tracked — regenerate it, never hand-edit around `project.yml`. Locally build with the **workspace** (`ChatArk.xcodeproj/project.xcworkspace`), not `-project` (SPM resolution).
- CI (`.gitlab-ci.yml`): `ios:version` → `build:ios:verify` / `build:ios:release` → `test:unit` (blocking) → `deploy:testflight` (main, iOS-path changes, **not manual**; needs green `test:unit`) → `create-isc-release`. Xcode jobs run only on the macOS runner (id 9, tags `macos`/`ios`).
- Signing via fastlane **match**. Push tokens register with Notify (slug `chatark`).
