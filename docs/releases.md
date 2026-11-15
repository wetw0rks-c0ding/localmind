# Release channels

LocalMind ships through three channels, all built by GitHub Actions and
published as GitHub Releases on this fork.

| Channel  | Trigger | Tag format | Published as | Artifacts |
| --- | --- | --- | --- | --- |
| **nightly** | cron `17 4 * * *` UTC (and manual) from `master` | `nightly-YYYYMMDD-<sha7>` | prerelease, last 7 kept | APK |
| **beta** | every push to the `beta` branch (and manual) | `v<version>-beta.<run>` | prerelease, last 10 kept | APK |
| **stable** | pushing a tag `v1.9.2` or `v1.9.2+97` | `v<version>` | full release (`--latest`) | APK + AAB |

Workflows:

- `.github/workflows/_build.yml` — shared reusable pipeline (versioning, analyze, test, build, publish, prune).
- `.github/workflows/nightly.yml` — nightly schedule/manual.
- `.github/workflows/beta.yml` — beta branch/manual.
- `.github/workflows/release.yml` — stable tags.

## Version code ladder

`pubspec.yaml` holds `version: 1.9.1+96` (name + build number `N = 96`).
Android `versionCode` is computed per channel so that nightlies and betas never
collide with each other or with stable:

| Channel | `versionName` | `versionCode` |
| --- | --- | --- |
| stable | tag name, e.g. `1.9.2` | `N * 1000` (e.g. `97000`) |
| beta | `1.9.1-beta.<run>` | `N * 1000 + 100 + run % 100` (e.g. `96123`) |
| nightly | `1.9.1-nightly.YYYYMMDD` | `N * 1000 + 500 + run % 400` (e.g. `96623`) |

Consequences:

- A stable release always upgrades over betas and nightlies of the same base
  version (higher `versionCode`).
- Nightlies and betas of a base version older than the latest stable will not
  install over it without `adb install -r -d`; stay on your channel or install
  with `-d`.

## Cutting a release

Stable:

```bash
# bump pubspec.yaml version first, e.g. 1.9.2+97
git tag v1.9.2+97
git push origin v1.9.2+97
```

Beta:

```bash
git checkout -B beta
git push origin beta        # builds and publishes v<version>-beta.<run>
```

Nightly: no action — or run the `nightly` workflow manually from the Actions tab.

## Signing

Without secrets, CI builds are debug-signed (Gradle falls back to the debug
config when `android/key.properties` is absent), which is fine for nightlies and
internal testing but **not** for Play uploads.

Add these repository secrets to sign with your own keystore:

| Secret | Contents |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_STORE_PASSWORD` | keystore password |

The workflow writes `android/key.properties` and the keystore at build time;
nothing is committed.

## Retention

Nightlies keep the 7 newest releases (older tags and releases are deleted
automatically); betas keep the 10 newest. Stable releases are never pruned.
Adjust via the `retention` input in `nightly.yml` / `beta.yml`.
