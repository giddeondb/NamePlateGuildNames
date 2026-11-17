# Publishing NamePlateGuildNames

## CurseForge automatic packaging

Project: https://authors.curseforge.com/#/projects/1812902

GitHub's push webhook sends source changes to CurseForge's native packager. The webhook token is kept in GitHub's webhook configuration, never in this repository. This uses the same publishing method as ForeverModels.

`.pkgmeta` packages one `NamePlateGuildNames/` folder and excludes screenshots, tests, tools, and publishing instructions. The TOC targets only Forever interface 16001. The existing LICENSE is included without packager replacement.

In the CurseForge project's source/packaging settings, select this GitHub repository and tag-only builds. Confirm the resulting file targets WoW Forever 1.60.1. Untagged builds, if enabled on CurseForge, are alpha builds; stable tags such as `v0.2.2` are releases.

For a release:

1. Update the version in the TOC, both Lua status strings, and changelog.
2. Run `lua5.1 tests/lifecycle.lua NamePlateGuildNames.lua` and `python3 tools/package.py`.
3. Commit and push `main`, then push an annotated version tag.
4. Verify CurseForge's build and file status. GitHub webhook acceptance alone does not prove that a file has been packaged and approved.

GitHub release ZIPs are published separately using `tools/package.py`; the CurseForge webhook does not create a GitHub release. Never move or reuse a published version tag.

## Project description and screenshots

`docs/curseforge-description.md` is the prepared public description. Its screenshots use direct GitHub-hosted PNG URLs under `docs/images/curseforge/`. These copies have a maximum dimension of 840 pixels, below the project's 850-pixel limit; the original screenshots remain unchanged.

If the editor requires image uploads, upload the two PNGs from that directory. Insert them into the description rather than using the full-size files. The logo is a separate design asset and is not part of the addon package.

References: [automatic packaging](https://support.curseforge.com/support/solutions/articles/9000197281) and [PackageMeta](https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file).
