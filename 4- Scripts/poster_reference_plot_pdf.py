from pathlib import Path
import numpy as np,pandas as pd,json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
R=Path(__file__).resolve().parents[1];cfg=json.loads((R/'settings.json').read_text());a=cfg['normalized_floor']
with np.load(R/'data/native_cells.npz') as d:speed=d['speed_m_s'];bio=d['biofilm']
assert np.all(np.isfinite(speed)) and np.all(speed>=0)
mean=float(speed.mean());original_u=speed/mean
# Identical edges for both treatments; 1e-4 is an exact bin edge.
edges=np.r_[np.geomspace(1e-7,1e-4,61)[:-1],np.geomspace(1e-4,original_u.max(),101)]
edges[-1]=original_u.max()
(R/'plots').mkdir(exist_ok=True);(R/'results').mkdir(exist_ok=True)
fig,ax=plt.subplots(figsize=(10,6.5));fig.subplots_adjust(bottom=.24,top=.84)
rows=[]
for label,mask,color in [('Inside biofilm',bio,'#16749b'),('Outside biofilm',~bio,'#b45e24')]:
 u=np.maximum(original_u[mask],a);tail=u[u>a];n=len(u);atom=int((u==a).sum())
 counts,_=np.histogram(tail,edges);width=np.diff(edges);density=counts/(n*width)
 assert counts.sum()==len(tail)
 integral=float(np.dot(density,width));mass=atom/n
 np.testing.assert_allclose(integral+mass,1,atol=1e-12)
 np.testing.assert_allclose(u,np.maximum(speed[mask],a*mean)/mean,rtol=1e-12)
 centers=(edges[:-1]+edges[1:])/2
 pd.DataFrame(dict(left=edges[:-1],right=edges[1:],center=centers,count=counts,density=density)).to_csv(R/'results'/f'{label.split()[0].lower()}_density.csv',index=False)
 rows.append(dict(region=label,reference_mean_m_s=mean,normalized_floor=a,equivalent_dimensional_floor_m_s=a*mean,n_total=n,n_continuous=len(tail),point_mass_count=atom,point_mass_probability=mass,continuous_integral=integral,mean_floored_normalized_speed=u.mean(),variance_ln_floored_normalized_speed=np.log(u).var(),probability_below_display=(u<1e-4).mean(),probability_above_display=(u>10).mean()))
 ax.loglog(centers,np.where(counts>0,density,np.nan),color=color,lw=2,label=label)
ax.set_xlabel(r'Normalized velocity $u_f=\max(v/\langle v\rangle_{\mathrm{sample}},a)$',fontsize=12)
ax.set_ylabel('Probability density',fontsize=13);ax.grid(alpha=.2,which='both');ax.legend(frameon=False)
ax.set_title(r'T12, $K_b=10^{-12}$ m²'+f'\nNormalized-velocity floor: {a:g}',fontsize=16)
fig.text(.125,.055,'Shared original whole-sample mean; floor probability recorded separately, not drawn as a spike.\nContinuous density retains its original probability weight; display cropping is not renormalized.',fontsize=9)
for ext in ['png','pdf','svg']:fig.savefig(R/'plots'/f'velocity_PDF_full_extent.{ext}',dpi=240)
ax.set_xlim(1e-4,10);visible=[]
for line in ax.lines:
 x,y=line.get_data();visible.extend(y[(x>=1e-4)&(x<=10)&np.isfinite(y)&(y>0)])
ax.set_ylim(min(visible)/2,max(visible)*2)
for ext in ['png','pdf','svg']:fig.savefig(R/'plots'/f'velocity_PDF_contour_range.{ext}',dpi=240)
pd.DataFrame(rows).to_csv(R/'results/summary.csv',index=False)
print(pd.DataFrame(rows).to_string(index=False))
