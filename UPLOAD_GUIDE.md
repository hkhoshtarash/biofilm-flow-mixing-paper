# Uploading and updating this repository

The repository is public. Anyone can view its code and public release assets. Its initial four-folder snapshot is uploaded under `data-v1`; no collaborator invitation is required to download it.

## Small changes: scripts, README files, configuration

For a small file, open the appropriate GitHub folder, select **Add file → Upload files**, upload the changed file, and commit. Browser uploads are limited to 25 MiB per file. Avoid uploading large data through that button.

Or use a local clone:

```bash
git clone https://github.com/hkhoshtarash/biofilm-flow-mixing-paper.git
cd biofilm-flow-mixing-paper
# Copy/edit the files you intend to update, then inspect the changes.
git status
git add '4- Scripts'
git diff --cached
git commit -m "Update analysis scripts"
git push origin main
```

Only stage intended source-code edits. Do not add the restored large data files to ordinary Git. The supplied .gitignore keeps the original release-only data paths out of normal staging.

## New complete four-folder data snapshot

Use the updated source folder containing all four original directories and the desired scripts. Python 3.11+ and the GitHub CLI are required. Run the archive builder from a clone. Choose a new, empty output directory outside the source folder, and a new release tag (for example `data-v2`):

```bash
python3 '4- Scripts/build_data_archives.py' \
  --source '/path/to/Open Section research' \
  --output '/path/to/new-assets-directory' \
  --tag data-v2
```

The builder includes every research file in the four directories, retains relative paths, computes per-file hashes, and splits archives into parts no larger than 1800 MiB. It does not upload or publish anything by itself. Do not modify the source files while archiving.

Copy the new `release_assets.json` and `SHA256SUMS` from the asset directory to the clone's root. Copy any changed small scripts/configuration files into the corresponding tracked repository folders, and update folder file indexes if files were added or removed. Commit and push the reviewed changes. Update the README's release link from `data-v1` to the new tag.

After checking which files will become public, upload the new release:

```bash
gh auth login
gh release create data-v2 --repo hkhoshtarash/biofilm-flow-mixing-paper \
  --target main --title 'Research data — version 2' \
  --notes 'Updated four-folder dataset; see release_assets.json and SHA256SUMS.' \
  /path/to/new-assets-directory/*
```

For a draft that you want to inspect first, add `--draft`; publish it through GitHub after checking the files. Each archive part must remain below 2 GiB. Do not replace old data-release files silently; a new tag preserves the earlier snapshot.

## Download and verify

From the updated clone run `python3 download_data.py --output /path/to/new-restored-folder`. It uses the release tag in `release_assets.json`, validates archive hashes, and verifies every restored file. Existing conflicting files are preserved rather than overwritten.

Manual downloads: fetch all release parts and `SHA256SUMS`, run `sha256sum -c SHA256SUMS`, then concatenate each prefix in lexical filename order, e.g. `cat 03_fields.tar.gz.part-* | tar -xz`.
