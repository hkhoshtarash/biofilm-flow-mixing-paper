# Updating the public repository

## The analysis folder

Keep `4- Scripts` limited to these two MATLAB files:

- `calculate_L_star.m`
- `calculate_sigma_squared.m`

Edit either through GitHub, or upload the replacement file using **Add file → Upload files**. Keep method explanations and usage examples in the comments inside each file.

## Concentration fields

All concentration MAT files are available in six direct release assets: `T0.zip`, `T6.zip`, `T9.zip`, `T10.zip`, `T12.zip`, and `T13.zip`. Each ZIP contains a stage-named directory with all MAT files from the corresponding supplied concentration folder.

For a new data version:

1. ZIP all MAT files in each stage folder, retaining the stage name as the ZIP's top-level folder.
2. Open GitHub **Releases → Draft a new release**, choose a new version tag, and upload the six ZIPs.
3. Update the download links in the main README and field-folder README to the new release.
4. Retain prior releases for reproducibility. Do not replace data silently under an old version tag.

Browser uploads into the normal Git file tree are unsuitable for these large datasets. Release assets keep the full MAT files downloadable without putting gigabytes in Git history.

## Complete-data download manifests

The root `release_assets.json` records the full four-folder snapshot. Unchanged image, case, and combined field archives continue to use data-v1; the replacement two-file Scripts archive uses data-v2. `download_data.py` follows the release tag recorded for each asset. If you change the full dataset or either MATLAB file and want the complete-data downloader to reflect that change, regenerate the affected archive and its per-file/archive hashes, then update the manifest. Direct stage ZIPs are also indexed there.

`data-v1` retains the older script collection for historical reproducibility; `data-v2` and the current repository contain only the two MATLAB calculation files in `4- Scripts`.
