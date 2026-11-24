"""Population variance of log normalized speed, matching the supplied poster code.

u = speed / mean(speed over original whole fluid sample)
u_f = max(u, normalized_floor)
sigma2 = Var_population(ln(u_f))

The mean is calculated ONCE, BEFORE flooring or splitting biofilm regions.
"""
import numpy as np


def sigma_squared(velocity, *, component_axis=None, fluid_mask=None,
                  biofilm_mask=None, normalized_floor=1e-4):
    a = np.asarray(velocity)
    if np.iscomplexobj(a):
        raise ValueError('Velocity must be real')
    a = np.asarray(a, dtype=float)
    speed = np.linalg.norm(a, axis=component_axis) if component_axis is not None else a
    if not np.isfinite(normalized_floor) or normalized_floor <= 0:
        raise ValueError('normalized_floor must be finite and positive')
    fluid = np.isfinite(speed)
    if fluid_mask is not None:
        mask = np.asarray(fluid_mask)
        if mask.dtype != bool or mask.shape != speed.shape:
            raise ValueError('fluid_mask must be boolean and match the speed shape')
        fluid &= mask
    values = speed[fluid]
    if not values.size or np.any(values < 0):
        raise ValueError('Need finite nonnegative fluid speeds')
    reference_mean = float(values.mean())
    if reference_mean <= 0:
        raise ValueError('Whole-sample mean speed must be positive')
    u = values/reference_mean
    floored = np.maximum(u, normalized_floor)
    groups = [('Whole fluid sample', np.ones(values.size, dtype=bool))]
    if biofilm_mask is not None:
        bio = np.asarray(biofilm_mask)
        if bio.dtype != bool or bio.shape != speed.shape:
            raise ValueError('biofilm_mask must be boolean and match speed shape')
        bio = bio[fluid]
        groups.extend([('Inside biofilm', bio), ('Outside biofilm', ~bio)])
    result = []
    for region, selected in groups:
        v = floored[selected]
        if not v.size:
            raise ValueError(f'No valid fluid samples in {region}')
        logs = np.log(v)
        atom = int(np.sum(u[selected] <= normalized_floor))
        result.append({
            'region':region, 'reference_mean_m_s':reference_mean,
            'normalized_floor':float(normalized_floor),
            'equivalent_dimensional_floor_m_s':float(normalized_floor*reference_mean),
            'n_total':int(v.size), 'n_continuous':int(v.size-atom),
            'point_mass_count':atom, 'point_mass_probability':float(atom/v.size),
            'mean_floored_normalized_speed':float(v.mean()),
            'variance_ln_floored_normalized_speed':float(logs.var(ddof=0)),
            'mean_ln_floored_normalized_speed':float(logs.mean()),
        })
    return result
