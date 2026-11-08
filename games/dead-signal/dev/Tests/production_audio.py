"""Strict additive production audio source normalization; immutable staging evidence retained."""
import hashlib
from pathlib import Path
DEV=Path(__file__).resolve().parents[1]
STAGED_BLOB='88cccbed93fabff62c72c170a595ea7f6338216e'
PRODUCTION_BLOB='8a314e4cec13a3d1f3e231628be203c36a493412'
BLOCK_BLOB='d4c907b38e250ebf8a92c07d4885b03dd2156616'
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def staged_config(source):
    from audio_b2_scope import config_before
    try:source=config_before(source)
    except AssertionError as error:raise ValueError(str(error)) from error
    if blob(source)!=PRODUCTION_BLOB:raise ValueError('Unreviewed production Config bytes')
    block=(DEV/'Reviews/production-batch1/PRODUCTION-BINDINGS.luau.txt').read_bytes()
    if blob(block)!=BLOCK_BLOB or source.count(block)!=1:raise ValueError('Unreviewed/duplicate production block')
    staged=source.replace(block,b'',1)
    if blob(staged)!=STAGED_BLOB:raise ValueError('Accepted staging source changed')
    return staged
