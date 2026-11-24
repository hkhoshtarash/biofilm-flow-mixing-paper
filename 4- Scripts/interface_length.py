"""Interface arc length and log-speed variance; no changes to source arrays."""
from pathlib import Path
import numpy as np
from scipy.io import loadmat
import contourpy


def load_array(path, variable=None):
    """Read a real numeric 2-D MAT variable or a headerless numeric CSV matrix.

    MATLAB v7.3/HDF5 files need conversion to v7 or a dedicated HDF5 loader.
    CSV component/coordinate tables must be parsed explicitly by the caller.
    """
    path = Path(path)
    if path.suffix.lower() == '.csv':
        array = np.loadtxt(path, delimiter=',', ndmin=2)
    elif path.suffix.lower() == '.mat':
        values = loadmat(path)
        if variable is None:
            keys = [k for k, v in values.items() if not k.startswith('__')
                    and isinstance(v, np.ndarray) and v.ndim == 2
                    and np.issubdtype(v.dtype, np.number)]
            if len(keys) != 1:
                raise ValueError(f'{path}: specify variable; numeric arrays are {keys}')
            variable = keys[0]
        if variable not in values:
            raise ValueError(f'{path}: missing variable {variable}')
        array = values[variable]
    else:
        raise ValueError('Use a .mat or headerless numeric .csv file')
    if np.iscomplexobj(array):
        raise ValueError('Array must be real')
    array = np.asarray(array, dtype=float)
    if array.ndim != 2:
        raise ValueError('Array must be two-dimensional')
    return array


def interface_length(concentration, *, dx, dy, reference_length, level=0.5):
    """Sum Euclidean arc lengths of all C=level contours, then divide by L0.

    Rows run along y, columns along x. dx, dy, L0 share physical length units.
    Nonfinite nodes are masked; triangles with three valid corners are retained
    (ContourPy corner_mask=True, matching the supplied MATLAB contour outputs).
    No smoothing, clipping, interpolation across solids, or artificial joins.
    """
    c = np.asarray(concentration)
    if np.iscomplexobj(c) or c.ndim != 2 or min(c.shape) < 2:
        raise ValueError('Concentration must be a real matrix, at least 2 by 2')
    c = np.asarray(c, dtype=float)
    if not all(np.isfinite(v) and v > 0 for v in [dx, dy, reference_length]):
        raise ValueError('dx, dy, and reference_length must be finite and positive')
    if not np.isfinite(level) or not np.isfinite(c).any():
        raise ValueError('A finite contour level and some finite data are required')
    generator = contourpy.contour_generator(
        x=(np.arange(c.shape[1]) + 1) * dx,
        y=(np.arange(c.shape[0]) + 1) * dy,
        z=np.ma.masked_invalid(c), name='serial', corner_mask=True,
        line_type='Separate')
    lines = generator.lines(float(level))
    lengths = [float(np.linalg.norm(np.diff(line, axis=0), axis=1).sum())
               for line in lines]
    length = float(sum(lengths))
    return {'length': length, 'L_star': length / reference_length,
            'n_contours': len(lines), 'segment_lengths': lengths}

