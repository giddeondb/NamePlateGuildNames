# Publishing NamePlateGuildNames

## Automatic GitHub releases

Every new first-parent commit on `main` publishes a minor release unless its subject or body contains `[skip ci]` or `[ci skip]`. Skipped commits stay skipped during future catch-up runs; their changes can be included in a later eligible release. Documentation and logo changes also publish releases unless marked to skip.

Automation starts after commit `52cf5e118fc88e29997a2a3d365fef3882d7f516`. Earlier commits and existing releases are not republished. The first automated version is `0.3.0`; later versions increment the highest numeric release tag's minor component and reset patch to zero.

1. Make changes and run `lua5.1 tests/lifecycle.lua NamePlateGuildNames.lua`, `luac5.1 -p NamePlateGuildNames.lua`, and `python3 -m unittest discover -s tests -p 'test_release.py' -v`.
2. Commit and push to `main`, or merge a pull request into `main`.
3. Check the **Publish addon** GitHub Actions workflow and the latest release download.

Do not manually bump versions or push release tags. Automation creates a release commit whose parent is the source main commit. Only the TOC version and generated changelog entry change in that release commit. The version tag points to it; generated release commits are never pushed back to main. Main keeps its development version, and the addon reads the installed version from TOC metadata for load messages and `/ngn status`.

This uses the same release reconciliation design as ForeverModels. Runs are serialized. Each run scans main's first-parent history to catch commits whose queued run was replaced. Tags reserve versions and record source SHAs before draft releases are created. A retry resumes a reserved tag or unpublished draft; it never rewrites a published release or moves an existing tag.

The workflow uses GitHub's built-in token with `contents: write`. No personal access token is required for GitHub releases.

## Checks and artifacts

Before creating a release tag, automation runs the Lua lifecycle tests and syntax check, verifies version metadata and changelog, and builds reproducible ZIPs. It uploads both `NamePlateGuildNames-VERSION.zip` and byte-identical `NamePlateGuildNames.zip` to a draft, then publishes it as Latest.

ZIPs contain exactly one `NamePlateGuildNames/` folder with Lua, TOC, README, changelog, and license. Tests, screenshots, logos, developer tools, settings, and filesystem links are excluded. The AddOns-menu gear uses a built-in game texture and needs no image file in the ZIP. README screenshot links are converted to the corresponding release tag's public URLs.

Automated checks do not establish new in-game compatibility. Friendly guild labels were confirmed on client 1.60.1 build 70938. Verify cast-bar layout, untargeted players, combat, range changes, reload, and instance transitions after relevant client changes.

## Retrying failures

After fixing a transient failure, use **Actions → Publish addon → Run workflow → main**. Existing release tags and drafts resume with their original source and version. Published releases are skipped. A validation failure stops subsequent releases; inspect its log before retrying.

## CurseForge automatic packaging

Project: https://authors.curseforge.com/#/projects/1812902

The existing GitHub push webhook sends release tags to CurseForge's native packager. Its account token is stored in GitHub's webhook configuration, never in this repository. CurseForge packaging is separate from GitHub release ZIP publication, and may begin as soon as the tag is pushed.

`.pkgmeta` packages one `NamePlateGuildNames/` folder, excludes development assets, and retains the existing BSD license. The TOC declares project 1812902 and only Forever interface 16001.

In the CurseForge author console, confirm this source repository and select tag-only packaging. GitHub sends branch pushes too; if untagged packaging is enabled on CurseForge, those builds may appear as alphas. Verify the generated file targets WoW Forever 1.60.1. The webhook accepted `v0.2.2`, but author-console tag-only settings and file approval were not verified because the browser was signed out.

A successful webhook delivery only confirms acceptance, not a completed or approved file. Check build and file status in the author console before announcing a CurseForge release. Do not add a separate upload workflow alongside this webhook, which could produce duplicate files.

## Description and images

`docs/curseforge-description.md` contains the prepared public description. Screenshot copies under `docs/images/curseforge/` are at most 840 pixels on either side, below the 850-pixel limit. Original screenshots remain in `docs/images/`.

The approved wide logo is `docs/images/logo-v2.png`. Use the 800×800 `docs/images/logo-curseforge.png` for CurseForge's square project-logo crop. The original ornate concept has been removed.

References: [automatic packaging](https://support.curseforge.com/support/solutions/articles/9000197281) and [PackageMeta](https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file).
