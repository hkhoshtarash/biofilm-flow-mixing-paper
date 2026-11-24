"""Archive every data file in the four supplied folders; never publish anything.

Usage: python build_data_archives.py --source PATH --output EMPTY_PATH
Outputs multipart tar.gz archives (<2 GiB per part), checksums, and manifests.
Python 3.11+. Only generated/tool metadata directories are excluded.
"""
import argparse,hashlib,json,tarfile
from pathlib import Path
FOLDERS=['1- Biofilm section images','2- openFOAM_setup_cases','3- Velocity_Conc_fields','4- Scripts']
EXCLUDE={'.git','.agents','.aws','.codex','__pycache__','.DS_Store'}
LIMIT=1800*1024**2

class Parts:
    def __init__(self,prefix):self.prefix=prefix;self.files=[];self.f=None;self.size=LIMIT
    def write(self,data):
        remaining=memoryview(data)
        while len(remaining):
            if self.size==LIMIT:
                if self.f:self.f.close()
                p=self.prefix.with_name(self.prefix.name+f'.part-{len(self.files):02d}')
                self.f=p.open('xb');self.files.append(p);self.size=0
            block=remaining[:LIMIT-self.size];self.f.write(block);self.size+=len(block);remaining=remaining[len(block):]
        return len(data)
    def close(self):
        if self.f:self.f.close()

class HashReader:
    def __init__(self,source):self.source=source;self.hash=hashlib.sha256()
    def read(self,n):
        block=self.source.read(n);self.hash.update(block);return block

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--tag',default='data-v1',help='GitHub release tag for these assets')
    a=p.parse_args();root=a.source.resolve();out=a.output.resolve()
    if out==root or root in out.parents:raise ValueError('Output must be outside source')
    out.mkdir(parents=True,exist_ok=True)
    if any(out.iterdir()):raise ValueError('Use an empty output folder')
    manifest={'release_tag':a.tag,'repository':'hkhoshtarash/biofilm-flow-mixing-paper','groups':[],'files':[]}
    assets=[]
    for index,name in enumerate(FOLDERS,1):
        folder=root/name
        if not folder.is_dir():raise FileNotFoundError(folder)
        files=sorted(q for q in folder.rglob('*') if q.is_file() and not any(x in EXCLUDE for x in q.relative_to(root).parts))
        prefix=f'{index:02d}_'+['images','cases','fields','scripts'][index-1]
        writer=Parts(out/(prefix+'.tar.gz'));entries=[]
        print(name,len(files),'files',flush=True)
        try:
            with tarfile.open(fileobj=writer,mode='w|gz',compresslevel=1) as archive:
                for q in files:
                    if q.is_symlink():raise ValueError(f'Symlink not supported: {q}')
                    before=q.stat();rel=q.relative_to(root).as_posix();info=archive.gettarinfo(str(q),arcname=rel)
                    # Do not disclose local account identities in public archive metadata.
                    info.uid=info.gid=0;info.uname=info.gname=''
                    with q.open('rb') as source:
                        reader=HashReader(source);archive.addfile(info,reader)
                    after=q.stat()
                    if before.st_size!=after.st_size or before.st_mtime_ns!=after.st_mtime_ns:raise RuntimeError(f'Source changed while archiving: {q}')
                    entry={'path':rel,'bytes':before.st_size,'sha256':reader.hash.hexdigest(),'group':prefix}
                    manifest['files'].append(entry);entries.append(entry)
        finally:writer.close()
        group_assets=[]
        for q in writer.files:
            with q.open('rb') as f:digest=hashlib.file_digest(f,'sha256').hexdigest()
            asset={'name':q.name,'bytes':q.stat().st_size,'sha256':digest}
            assets.append(asset);group_assets.append(asset)
        manifest['groups'].append({'id':prefix,'folder':name,'file_count':len(entries),'source_bytes':sum(x['bytes'] for x in entries),'assets':group_assets})
        print('Completed',name,flush=True)
    (out/'release_assets.json').write_text(json.dumps(manifest,indent=2))
    with (out/'SHA256SUMS').open('w') as f:
        for asset in assets:f.write(asset['sha256']+'  '+asset['name']+'\n')
        with (out/'release_assets.json').open('rb') as src:h=hashlib.file_digest(src,'sha256').hexdigest()
        f.write(h+'  release_assets.json\n')
    print('Local archives and complete source hashes created; no upload performed.')

if __name__=='__main__':main()
