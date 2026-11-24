"""Download public release assets, verify SHA-256, and restore the four folders.

Run from a clone: python3 download_data.py
Optional: --output PATH --group 01_images (or 02_cases, 03_fields, 04_scripts).
Existing files are preserved if identical; conflicting files are never overwritten.
"""
import argparse,hashlib,json,tarfile,urllib.request
from pathlib import Path,PurePosixPath

class JoinedParts:
    def __init__(self,paths):self.paths=iter(paths);self.f=None
    def read(self,n):
        if n<0:raise ValueError('Only bounded streaming reads are supported')
        blocks=[];left=n
        while left:
            if self.f is None:
                try:self.f=next(self.paths).open('rb')
                except StopIteration:break
            data=self.f.read(left)
            if not data:self.f.close();self.f=None;continue
            blocks.append(data);left-=len(data)
        return b''.join(blocks)
    def close(self):
        if self.f:self.f.close()

def digest(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,default=Path(__file__).resolve().parent)
    p.add_argument('--group',action='append',choices=['01_images','02_cases','03_fields','04_scripts'])
    p.add_argument('--cache',type=Path)
    args=p.parse_args();root=args.output.resolve();root.mkdir(parents=True,exist_ok=True)
    cache=(args.cache or root/'.data-downloads').resolve();cache.mkdir(parents=True,exist_ok=True)
    manifest=json.loads(Path(__file__).with_name('release_assets.json').read_text())
    expected={f['path']:f for f in manifest['files']}
    for group in manifest['groups']:
        if args.group and group['id'] not in args.group:continue
        paths=[]
        for asset in group['assets']:
            tag=asset.get('release_tag',manifest['release_tag'])
            base=f'https://github.com/{manifest["repository"]}/releases/download/{tag}/'
            path=cache/asset['name'];paths.append(path)
            if not path.is_file() or path.stat().st_size!=asset['bytes'] or digest(path)!=asset['sha256']:
                partial=path.with_name(path.name+'.partial')
                print('Downloading',asset['name'],flush=True)
                with urllib.request.urlopen(base+asset['name']) as src,partial.open('wb') as dst:
                    while block:=src.read(1024**2):dst.write(block)
                if partial.stat().st_size!=asset['bytes'] or digest(partial)!=asset['sha256']:
                    raise RuntimeError(f'Integrity check failed for {asset["name"]}')
                partial.replace(path)
        reader=JoinedParts(paths);restored=set()
        try:
            with tarfile.open(fileobj=reader,mode='r|gz') as archive:
                for member in archive:
                    name=member.name;rel=PurePosixPath(name)
                    if rel.is_absolute() or '..' in rel.parts or name not in expected:
                        raise ValueError(f'Unexpected archive path: {name}')
                    if not member.isfile():raise ValueError('Only regular files may be restored')
                    if name in restored:raise ValueError(f'Duplicate archive member: {name}')
                    target=(root/Path(*rel.parts)).resolve()
                    if root not in target.parents:raise ValueError('Archive path escapes output')
                    record=expected[name]
                    if record['group']!=group['id'] or record['bytes']!=member.size:
                        raise ValueError('Archive contents do not match manifest')
                    src=archive.extractfile(member)
                    if target.exists():
                        if not target.is_file() or digest(target)!=record['sha256']:
                            raise FileExistsError(f'Preserving changed file; choose a new output folder: {target}')
                        # Stream past the data even when an identical tracked file exists.
                        while src.read(1024**2):pass
                    else:
                        target.parent.mkdir(parents=True,exist_ok=True)
                        with target.open('xb') as dst:
                            while block:=src.read(1024**2):dst.write(block)
                        if digest(target)!=record['sha256']:
                            raise RuntimeError(f'Restored file hash mismatch: {name}')
                        target.chmod(member.mode&0o777)
                    restored.add(name)
        finally:reader.close()
        wanted={f['path'] for f in manifest['files'] if f['group']==group['id']}
        if restored!=wanted:raise RuntimeError(f'Incomplete archive group: {group["id"]}')
        print('Restored and verified',group['folder'],len(restored),'files',flush=True)
    print('Complete. Cache files can be removed after verifying your restored data.')

if __name__=='__main__':main()
