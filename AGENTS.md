# AGENTS.md

## Client Assets Gate (Mandatory)

Any change touching client-assets auto-installation must preserve the runtime contract below:

1. **Final install paths must remain OTC-standard**
   - `data/things/<version>/`
   - `data/sounds/<version>/`
   - runtime extras in expected runtime locations (for example `bin/*` when distributed upstream)

2. **No alternate permanent source of truth**
   - Do not move runtime loading to `client-assets/` (or any new root) as the primary runtime path.
   - Temporary/cache directories are allowed only as transient staging, never as final runtime source.

3. **Security defaults stay strict unless explicitly justified**
   - `strictManifestSha256 = true`
   - `allowRawFallbackHashMismatch = false`

4. **Cross-platform build safety**
   - Android must not require unsupported `libarchive` linkage.
   - Desktop archive extraction behavior must remain functional.

5. **Verification required in PR description**
   - Explicitly state tested install paths and expected runtime load behavior.

Reference: `docs/client-assets-auto-install.md`

## Official Desktop Builds and Releases

1. Official Windows and macOS client builds must run through GitHub Actions using standard GitHub-hosted runners.
2. Windows and macOS builds must be triggerable separately. Do not start a platform build unless the user requested it.
3. After triggering a build, provide the GitHub Actions run link and wait for the user to confirm completion or validation. Do not continuously monitor the run unless explicitly requested.
4. Do not create or publish a Release, update launcher manifests, or deploy an update merely because a build completed. Wait for explicit user approval.
5. A local macOS build is only allowed when the user explicitly requests a local build. Local builds are not the default official release process.
6. Keep official builds on standard runners while the repository is public. Do not switch to larger or paid runners without explicit approval.
