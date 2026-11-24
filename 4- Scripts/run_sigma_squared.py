"""Batch the six provided MAT speed grids; choose a fluid-mask policy explicitly."""
import argparse,csv,json
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from sigma_squared import sigma_squared


def array(path):
    values=loadmat(path)
    keys=[k for k,v in values.items() if not k.startswith('__')
          and isinstance(v,np.ndarray) and v.ndim==2 and np.issubdtype(v.dtype,np.number)]
    if len(keys)!=1: raise ValueError(f'Specify one numeric matrix in {path}: {keys}')
    return values[keys[0]]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--data-root',type=Path,default=Path(__file__).resolve().parents[1])
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--mask-policy',choices=['positive-speed','all-finite','concentration-finite'],required=True)
    p.add_argument('--normalized-floor',type=float,default=1e-4)
    args=p.parse_args(); root=args.data_root.resolve(); out=args.output.resolve()
    # Outputs must not overwrite any supplied input data.
    if out==root or root in out.parents: raise ValueError('Choose output outside the data root')
    out.mkdir(parents=True,exist_ok=True)
    target=out/'sigma_squared.csv'
    if target.exists(): raise FileExistsError(target)
    rows=[]
    for stage in ['T0','T6','T9','T10','T12','T13']:
        speed=array(root/f'3- Velocity_Conc_fields/VelocityField/{stage}.mat')
        if args.mask_policy=='positive-speed': mask=np.isfinite(speed)&(speed>0)
        elif args.mask_policy=='all-finite': mask=np.isfinite(speed)
        else:
            c=array(root/f'3- Velocity_Conc_fields/ConcentrationField/{stage}/C_cut_T2.mat')
            if c.shape!=speed.shape: raise ValueError('Concentration/speed shapes differ')
            mask=np.isfinite(c)
        for r in sigma_squared(speed,fluid_mask=mask,normalized_floor=args.normalized_floor):
            rows.append({'stage':stage,'mask_policy':args.mask_policy,**r})
    with target.open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    (out/'settings.json').write_text(json.dumps({'normalization':'original whole-fluid arithmetic mean before flooring',
      'normalized_floor':args.normalized_floor,'mask_policy':args.mask_policy,'variance_divisor':'N',
      'region_note':'No co-registered biofilm masks supplied; reports whole selected fluid sample only'},indent=2))
    print(target)


if __name__=='__main__': main()
