"""Recompute L and L* from all provided concentration snapshots, one at a time."""
import argparse,csv,json,re
from pathlib import Path
from interface_length import load_array,interface_length


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--data-root',type=Path,default=Path(__file__).resolve().parents[1])
    p.add_argument('--config',type=Path,default=Path(__file__).with_name('legacy_six_stages.json'))
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();root=args.data_root.resolve();output=args.output.resolve()
    if output==root or root in output.parents:raise ValueError('Choose output outside source tree')
    if output.exists():raise FileExistsError(output)
    output.parent.mkdir(parents=True,exist_ok=True)
    cfg=json.loads(args.config.read_text());rows=[]
    for st in cfg['stages']:
        paths=list((root/st['concentration_directory']).glob('C_cut_T*.mat'))
        if not paths:raise ValueError(f'No snapshots for {st["stage"]}')
        def time_of(path):
            m=re.fullmatch(r'C_cut_T([0-9]+(?:\.[0-9]+)?)\.mat',path.name)
            if not m:raise ValueError(path.name)
            return float(m.group(1))
        for path in sorted(paths,key=time_of):
            t=time_of(path);C=load_array(path,path.stem)
            L0=st.get('reference_length',cfg['legacy_width_fraction']*C.shape[1]*cfg['dx'])
            r=interface_length(C,dx=cfg['dx'],dy=cfg['dy'],reference_length=L0,level=cfg['concentration_level'])
            rows.append({'stage':st['stage'],'time_seconds':t,'time_normalized':t/st['ta_seconds'],
              'length_m':r['length'],'L_star':r['L_star'],'reference_length_m':L0,'n_contours':r['n_contours']})
        print(st['stage'],len(paths),'snapshots',flush=True)
    with output.open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)


if __name__=='__main__':main()
