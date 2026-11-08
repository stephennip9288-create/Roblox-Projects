"""Plot the actual exported policy; this is balance evidence, not a gameplay capture."""
from pathlib import Path
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

root=Path(__file__).resolve().parent.parent
data=json.loads((root/'Reviews/movement-batch2/Balance-Report.json').read_text())
rows=data['angles'];x=[r['degrees'] for r in rows]
plt.rcParams['svg.hashsalt']='dead-signal-batch2-movement'
fig,axes=plt.subplots(1,2,figsize=(12,4.4),layout='constrained')
ax=axes[0];ax.axvspan(0,30,color='#d9eee7',label='Forward sprint cone')
for key,label,color in [('sprintRequest','Sprint request','#087e75'),('walk','Normal walk','#243c59'),('Marathon','Marathon walk','#9e6c24'),('ADS','ADS walk','#9a4d70')]:
 ax.plot(x,[r[key] for r in rows],label=label,color=color,linewidth=2)
ax.set(xticks=[0,30,90,180],xticklabels=['Forward','30°','Strafe','Back'],ylabel='Speed cap (studs/s)',ylim=(0,30),title='Smooth angle-dependent caps')
ax.grid(alpha=.2);ax.legend(fontsize=8)
ax=axes[1];rounds=[r['round'] for r in data['pursuit']]
ax.plot(rounds,[r['shambler'] for r in data['pursuit']],color='#243c59',marker='o',label='Unchanged regular zombie')
ax.axhline(9.5,color='#9a4d70',linestyle='--',label='Backpedal 9.5')
ax.axhline(10.5,color='#9e6c24',linestyle='--',label='Strafe 10.5')
ax.axhline(16,color='#087e75',linestyle=':',label='Forward walk 16')
ax.set(xlabel='Round',ylabel='Speed (studs/s)',ylim=(0,19),title='Mid/late-round pressure without changing enemies')
ax.grid(alpha=.2);ax.legend(fontsize=8)
fig.suptitle('Batch 2 movement recommendations — native gameplay tuning pending',fontsize=12)
fig.savefig(root/'Reviews/movement-batch2/Directional-Speeds.svg',metadata={'Date':None})
svg=root/'Reviews/movement-batch2/Directional-Speeds.svg'
svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')
preview=root/'Validation/movement-batch2';preview.mkdir(parents=True,exist_ok=True)
fig.savefig(preview/'Directional-Speeds.png',dpi=140);plt.close(fig)
print('Plotted source-policy and pursuit values; no native testing is inferred.')
