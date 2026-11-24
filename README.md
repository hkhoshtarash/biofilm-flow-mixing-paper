# Biofilm-induced flow and mixing — research materials

Research materials accompanying **Biofilm-Induced Flow Heterogeneity Sustains Mixing Interface Deformation and Enhances Mixing-Limited Reactions in Porous Media**.

## The four supplied folders

1. **[1- Biofilm section images](1-%20Biofilm%20section%20images/)** — the six supplied TIFF image files, preserved as provided.
2. **[2- openFOAM_setup_cases](2-%20openFOAM_setup_cases/)** — flow and transport case directories for T0, T6, T9, T10, T12, and T13, including the supplied meshes and initial fields.
3. **[3- Velocity_Conc_fields](3-%20Velocity_Conc_fields/)** — velocity/speed MAT grids, concentration snapshots, saved L* tables, and the other files provided in this folder.
4. **[4- Scripts](4-%20Scripts/)** — the original L* script plus generalized Python/MATLAB L* functions and the updated sigma² calculation based on the supplied poster code.

All data files in the four supplied folders are preserved in the complete release archives. They have not been replaced with a different selection of files. New analysis scripts were added under `4- Scripts`.

## Download the complete data

**GitHub's “Download ZIP” button downloads the tracked code and smaller files, not all large data.** Large TIFFs, meshes, and field matrices are attached to the **[data-v1 release](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/tag/data-v1)** because normal GitHub Git storage blocks individual files larger than 100 MiB.

Clone or download this repository, then run Python 3.11+:

```bash
git clone https://github.com/hkhoshtarash/biofilm-flow-mixing-paper.git
cd biofilm-flow-mixing-paper
python3 download_data.py
```

The downloader verifies release SHA-256 checksums and restores the original four-folder hierarchy. Identical existing files are retained; conflicting files are not overwritten. About 10.6 GB of uncompressed source data is supplied; allow additional disk space for the compressed download cache. Use `--group 01_images`, `02_cases`, `03_fields`, or `04_scripts` to restore one group, or `--output /path/to/new-folder` for a separate destination. Release files can also be downloaded manually; concatenate each prefix's `.part-*` files in order before extracting the tar.gz archive.

`release_assets.json` lists every original file, byte size, and SHA-256, plus all archive parts. Each supplied folder has a `FILE_INDEX.csv` for browsing. Generated caches and tool metadata (`.git`, `.agents`, `.aws`, `.codex`, `__pycache__`) are not research data and are excluded.

## Sigma squared — the poster method

The new implementation uses the **original whole-fluid mean speed before flooring or splitting regions**:

`u = speed / mean_original_whole_fluid_speed`

`u_f = max(u, 1e-4)`

`sigma² = Var_population(ln(u_f))`

The `1e-4` floor applies to **normalized speed**, not dimensional m/s. The natural logarithm and population variance (divisor N) match the supplied poster script. Inside/outside biofilm statistics use the same whole-sample mean when a co-registered biofilm mask is supplied. The default batch operates on the provided scalar speed matrices, not on the poster's different native-cell sample.

After restoring the data:

```bash
python3 -m pip install -r '4- Scripts/requirements.txt'
python3 '4- Scripts/run_sigma_squared.py' \
  --data-root "$PWD" --mask-policy positive-speed --output ../sigma_results
python3 '4- Scripts/run_L_star.py' --data-root "$PWD" --output ../L_star_results.csv
```

The example's `positive-speed` mask assumes zeros are solid-coded. Actual zero-speed fluid points must instead be included in a verified fluid mask and will be floored after normalization. See **[4- Scripts/README.md](4-%20Scripts/README.md)** for mask options, MATLAB examples, region masks, and normalization details.

## Verification and interpretation

- Seven new Python tests cover the corrected sigma² calculation, including normalized flooring, a shared reference mean, valid fluid zeros, vector speed, and divisor N.
- On the original poster sample, Python reproduces both supplied regional variances and floor-mass counts. MATLAB uses the same formula, but its tests were not run in the preparation environment.
- The generalized L* calculation was checked on all 354 supplied concentration snapshots. Eight Python values differ slightly from saved MATLAB results, by at most approximately 0.001877 in L*. Exact cross-language contour equality is not claimed.
- The supplied model inputs were structurally inspected; OpenFOAM simulations were not rerun. The observed applications are `simpleFoam`, `hybridPorousPimpleFoam`, and `scalarTransportFoam`. The precise OpenFOAM distribution/version and custom solver revision should be specified from the authors' simulation records.
- Data are published here as supplied. The new image folder currently contains raw-named TIFFs; no new segmentation is claimed. Velocity MAT files contain scalar speed grids rather than native vector/component CSV tables. Image-phase labels, coordinate registration, units, and sampling choices require the authors' documentation for scientific reuse.

## Uploading later changes

The initial four-folder upload is already attached to `data-v1`. See **[UPLOAD_GUIDE.md](UPLOAD_GUIDE.md)** for updating scripts or publishing a new complete data release. Existing private working repositories remain separate.

## Attribution and licensing

Author attribution and licensing should follow the associated paper and the authors' agreed release terms. No new data/software license has been assigned automatically; public visibility alone does not grant a reuse license. Third-party OpenFOAM/solver software remains subject to its original licenses and citations.
