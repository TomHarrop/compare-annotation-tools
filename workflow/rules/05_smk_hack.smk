#!/usr/bin/env python3

logger.error("""
*******************************
* USING HACK FROM 05_smk_hack *
*******************************
""")

import json as _json
_orig_dumps = _json.dumps
def _dumps(obj, *args, **kwargs):
    kwargs.setdefault("default", str)
    return _orig_dumps(obj, *args, **kwargs)
_json.dumps = _dumps
