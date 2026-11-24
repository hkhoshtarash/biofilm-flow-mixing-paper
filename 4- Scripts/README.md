# Analysis scripts

## Sigma squared: corrected to the supplied poster method

The primary functions are `sigma_squared.py` and `sigma_squared.m`.

1. Compute scalar speed (pointwise Euclidean vector norm if components are supplied).
2. Compute the **original whole-fluid arithmetic mean speed**, before clamping or splitting regions.
3. Normalize: `u = speed / original_whole_mean`.
4. Set **all normalized speeds <= 1e-4 to 1e-4**, including valid fluid zeros.
5. Calculate `sigma² = Var_population(ln(max(u,1e-4)))`, with divisor **N**, not N-1.

Inside/outside biofilm groups use the same original whole-sample mean. The equivalent dimensional floor is `1e-4 * original_whole_mean`, NOT a fixed `1e-4 m/s`.

Python tests reproduce the attached poster's native-cell example: sigma²=3.457614746508199 inside biofilm and 3.899177935087911 outside; point-mass counts 4502 and 3759 respectively. This is a code regression test on the original poster sample, not a claim that the new six-stage gridded fields are the same sample. `poster_regression.json` records the comparison. The original plotting script is preserved as `poster_reference_plot_pdf.py`; it requires its original `settings.json` and `data/native_cells.npz` package and is not the batch entry point here.

### Python

Install `numpy`, `scipy`, and `contourpy` using `requirements.txt`. From the repository root, after downloading/restoring the data:

```bash
python3 '4- Scripts/run_sigma_squared.py' \
  --data-root "$PWD" --mask-policy positive-speed --output ../sigma_results
python3 -m unittest discover -s '4- Scripts' -p 'test_sigma_squared.py' -v
```

The mask choice is explicit because the speed matrices contain many zeros:

- `positive-speed`: assumes every zero is solid-coded; excludes zero points before computing the mean. Select this only if zero encodes solids, since it also excludes actual stagnant-fluid zeros.
- `concentration-finite`: uses the finite nodes of each stage's first concentration field as a candidate fluid mask. Use only if that is the intended domain.
- `all-finite`: includes all finite values, including zeros. Suitable only if those values truly belong to the fluid sample.

The batch driver reports the **whole selected fluid sample** for each stage because co-registered biofilm region masks are not included in these MAT files. To calculate inside/outside regions, supply an independently verified boolean biofilm mask to the general function; the binary images cannot be assumed to align with the cropped speed grids automatically.

```python
from sigma_squared import sigma_squared
rows = sigma_squared(speed, fluid_mask=fluid_mask, biofilm_mask=biofilm_mask)
# For vector components: sigma_squared(U, component_axis=-1, fluid_mask=fluid_mask)
```

Nonfinite speeds and masked solids are excluded. Valid fluid zeros are retained and floored after normalization. No flux/volume weighting is introduced; gridded points have equal weight.

### MATLAB

```matlab
addpath('4- Scripts');
test_sigma_squared;
run_sigma_squared(pwd, fullfile(tempdir,'sigma_squared.csv'), 'positive-speed');
rows = sigma_squared(speed, 'FluidMask', fluid_mask, 'BiofilmMask', biofilm_mask);
```

The MATLAB implementation uses the identical formula and explicitly divides the squared log deviations by N. MATLAB tests are included but could not be run in the preparation environment, whose MATLAB executable is empty. Tests in Python passed. No OpenFOAM simulations were rerun.

## Interface length and L*

Use `run_L_star.py` / `run_L_star.m` and the general `interface_length` functions. The old `L_start_calculation.m` is retained unchanged as supplied; it is a legacy reference, not the recommended entry point.

```bash
python3 '4- Scripts/run_L_star.py' --data-root "$PWD" --output ../L_star_results.csv
```

```matlab
addpath('4- Scripts');
run_L_star(pwd, fullfile(tempdir,'L_star_results.csv'));
```

The functions sum the physical arc lengths of all C=0.5 contours, without joining disconnected components, smoothing, or clipping the source concentrations. Python uses ContourPy corner_mask=True; MATLAB uses the original `contour` method in an invisible figure. General functions accept dx, dy, reference length, and contour level.

`legacy_six_stages.json` preserves dx=dy=8.3978e-6 m, L0=0.44*N_columns*dx, and each stage's saved time normalization. The velocity definition underlying the saved characteristic times is not inferred from the speed grids. Comparing all 354 supplied fields, 346 Python L* values agree numerically with the saved tables; eight differ by at most 0.001877 in L*. Exact Python/MATLAB equality is not claimed.

## Source data

The velocity MAT files are scalar speed grids. They cannot recover original vector components or native cell coordinates. Concentration MAT files are the supplied cropped/interpolated grids, with NaNs preserved. No new segmentation or scientific data corrections have been applied. Exact software versions, units, image registration/phase labels, and any paper-specific sampling choices should be documented by the authors.
