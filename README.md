# GlowPebbles Support

This public repository contains the support website and issue tracker for
GlowPebbles, a fully offline multi-touch Android game for toddlers.

Visit the website at <https://coastie-uk.github.io/GlowPebbles-support/> or use
the repository's issue forms to report a problem or share a suggestion.

The application source code is maintained separately and is not published in
this repository.

## Publish the latest APK

The checked-in `tools/Sync-LatestRelease.ps1` script copies a packaged APK and its
verified SHA-256 checksum from the neighbouring private GlowPebbles checkout. It
creates a versioned public download plus the stable `GlowPebbles-latest.apk` URL
used by the website. It does not build, sign, commit, or push anything.

From this repository:

```powershell
.\tools\Sync-LatestRelease.ps1
```

By default, the script reads `versionName` from `..\TinyTaps\app\build.gradle.kts`.
Use `-PrivateRepository` or `-Version` when the checkouts or release selection
differ. Review the resulting files before committing them.
