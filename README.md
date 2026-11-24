# Biofilm-induced flow and mixing — paper data and calculations

## Concentration fields: direct downloads

**All 354 concentration snapshots are included.** Download the MAT files separately for each stage:

- **[T0.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T0.zip)**
- **[T6.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T6.zip)**
- **[T9.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T9.zip)**
- **[T10.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T10.zip)**
- **[T12.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T12.zip)**
- **[T13.zip](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/download/data-v2/T13.zip)**

Each ZIP contains all 59 `C_cut_T*.mat` snapshots for that stage, plus all other MAT files supplied in its concentration folder. The stage names are experimental/model stages; the individual simulation times are in the `C_cut_T<time>.mat` filenames. See [the field folder](3-%20Velocity_Conc_fields/README.md) for details.

## The four folders

1. **[1- Biofilm section images](1-%20Biofilm%20section%20images/)** — supplied TIFF images.
2. **[2- openFOAM_setup_cases](2-%20openFOAM_setup_cases/)** — flow and transport cases for all six stages.
3. **[3- Velocity_Conc_fields](3-%20Velocity_Conc_fields/)** — velocity fields, all concentration snapshots, and saved L* tables.
4. **[4- Scripts](4-%20Scripts/)** — exactly two MATLAB calculation files:
   - **[calculate_L_star.m](4-%20Scripts/calculate_L_star.m)**
   - **[calculate_sigma_squared.m](4-%20Scripts/calculate_sigma_squared.m)**

The two calculation files are self-contained: no separate helper scripts or JSON configuration files are required. Each file contains usage examples and comments explaining its method and assumptions.

## Run the calculations in MATLAB

After restoring the complete data, open MATLAB in the repository root:

```matlab
addpath('4- Scripts');
calculate_L_star(pwd, fullfile(tempdir,'L_star.csv'));
calculate_sigma_squared(pwd, fullfile(tempdir,'sigma_squared.csv'), 'positive-speed');
```

The sigma² example explicitly assumes zero-speed matrix entries encode solids. Select an appropriate mask policy as explained in the function comments; valid stagnant-fluid zeros must be retained using a verified fluid mask.

**L*:** sum the physical arc lengths of all C=0.5 contour components and divide by the documented initial reference length. The supplied grid spacing and saved stage-specific time scales are preserved. NaN masks are retained; separate contours are not joined, smoothed, or clipped.

**σ²:** divide speed by the **original whole-fluid mean**, floor the **normalized speed** at `1e-4`, then compute the **population variance of its natural logarithm**, with divisor N. Inside/outside biofilm regions, when registered masks are provided, share that original whole-fluid mean. The threshold is dimensionless, not a fixed dimensional speed of 1e-4 m/s. Detailed comments are inside the MATLAB file.

## Download the complete four-folder dataset

GitHub's normal source-code ZIP does not include the large research-data files. The original release already contained all concentration MAT files in a combined archive; the updated release adds the easier per-stage ZIPs above and replaces the analysis folder with only the two MATLAB files.

To restore all data and the current two-file Scripts folder:

```bash
git clone https://github.com/hkhoshtarash/biofilm-flow-mixing-paper.git
cd biofilm-flow-mixing-paper
python3 download_data.py
```

The downloader uses Python 3.11+ and checks every archive and restored file against SHA-256 hashes. It reuses the unchanged image/case/field archives on data-v1 and restores the new two-file Scripts archive from **[data-v2](https://github.com/hkhoshtarash/biofilm-flow-mixing-paper/releases/tag/data-v2)**. Do not extract the old data-v1 Scripts archive over the current folder. Existing conflicting files are preserved rather than overwritten; use `--output /path/to/new-folder` if you have an older checkout with edited files.

The updated snapshot has 744 supplied files across the four folders, including the two MATLAB files. Data-v1 remains available as a historical snapshot with the superseded scripts. See [upload instructions](UPLOAD_GUIDE.md) for future changes.

## Validation and scientific notes

The normalized sigma² method reproduces the supplied poster's native-cell regional example in Python (inside: 3.457614746508199; outside: 3.899177935087911). MATLAB uses the same formula, but was not executed in the preparation environment. OpenFOAM simulations were not rerun. Author documentation should specify the actual solver version, image phase labels, coordinate registration, units, fluid masks, and any sampling choices. The image and field files are preserved as supplied; no new segmentation or vector-field reconstruction is claimed.

No new reuse license has been assigned automatically. Use the authors' agreed data/software license and preserve third-party solver licenses and citations.
