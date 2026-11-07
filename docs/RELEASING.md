# Releasing Auto Clicker

## First upload

The local project needs to be committed and pushed to
[`oyjt/auto-clicker`](https://github.com/oyjt/auto-clicker), including
`.github/workflows/release.yml`. This guide assumes the default branch is `main`.
For an empty remote repository and a local directory without Git history:

```sh
git init -b main
git remote add origin https://github.com/oyjt/auto-clicker.git
git add .
git diff --cached --stat
git commit -m "Initial import"
git push -u origin main
```

Review staged files before committing. If the remote already contains commits,
clone it and copy the project into that checkout instead of overwriting history.
GitHub Actions must be enabled for the repository. Organization or repository
policies must allow the workflow's `contents: write` permission.

## Record changes

Keep user-visible changes in `CHANGELOG.md`, under `## [Unreleased]`, using
`### Added`, `### Changed`, `### Fixed` or `### Removed` as needed.
Before a release, move those changes into a dated version section and leave
`Unreleased` available for the next version:

```markdown
## [Unreleased]

## [1.1.0] - YYYY-MM-DD

### Added

- Describe the change from the user's point of view.
```

Use exactly one nonempty section per version. Version numbers use three numeric
components (`X.Y.Z`); tags add a `v` prefix (`vX.Y.Z`). Suffixes such as `-beta.1`
are not currently supported. GitHub's pre-release checkbox is supported with a
numeric version tag. The initial `1.0.0` entry is prepared for the first release.

## Publish a release

1. Update and commit `CHANGELOG.md`. For local builds to show the same version,
   also update `CFBundleShortVersionString` and `CFBundleVersion` in
   `Resources/Info.plist`. Release builds override these from the tag and workflow
   run number without changing the source plist.
2. Test and package locally (replace `1.0.0` with the intended version):

   ```sh
   python3 scripts/test-release-notes.py
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
   CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
   swift test --disable-sandbox --cache-path .build/cache \
     --config-path .build/config --security-path .build/security
   ./scripts/package-dmg.sh 1.0.0
   ```

3. Push the release commit to GitHub. On the repository's **Releases** page,
   choose **Draft a new release**, create a tag such as `v1.0.0` targeting that
   commit, and copy the matching changelog section into the description.
   `build/AutoClicker-1.0.0-release-notes.md` contains the extracted section.
4. Select **Publish release**. The **Release DMG** workflow starts on
   [`release: published`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#release).
   It does not run for an unpublished draft or a tag push alone.
5. Wait for the workflow to finish and confirm these assets appear on the Release:

   - `AutoClicker-1.0.0-universal.dmg`
   - `AutoClicker-1.0.0-universal.dmg.sha256`
   - `AutoClicker-1.0.0-release-notes.md`

The workflow checks out the release tag, runs Swift and release-note tests, builds
both `arm64` and `x86_64`, verifies the app signature and DMG, and uploads the
assets using the built-in token. It preserves the Release's existing description.
It does not commit changes or create another Release. Downloads become available
only after the workflow finishes, even though the Release is already published.

## Failed runs and retries

Check the **Actions → Release DMG** logs. A missing changelog entry or invalid tag
fails before compilation. Fix source issues in a new release commit/tag; rerunning
an old Release still builds its original tagged commit.

For temporary runner/network failures, rerun the failed job. Existing release
assets are never automatically overwritten. If an upload partially succeeded,
download and verify the existing assets, then upload only the missing ones, or
remove those generated assets explicitly before rerunning. If [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
are enabled, publishing locks the Release and prevents this post-publication
upload workflow; disable that setting for this workflow or use a draft-first
release process instead.

## Signing and manual checks

The package uses an ad-hoc signature. Developer ID signing and Apple notarization
are not configured and no Apple credentials are needed. Gatekeeper may block a
downloaded build; see [Apple's guidance](https://support.apple.com/en-us/102445).
Do not commit private keys or certificates.

Before distributing, install the DMG on a Mac and verify Accessibility approval,
global shortcuts, pause/resume, multi-display positioning and actual mouse clicks
in a harmless target app. The packaging workflow checks both architectures but
does not run the app on Intel hardware. In-app automatic updates are not included.
