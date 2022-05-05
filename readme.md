# luigi_lua
Tool for unpack/repack gmsg files from EU ver. Luigi's Mansion 3DS

Running on luajit 2.1.0

based on:
https://github.com/Xzonn/LuigiMansion

import - Repack inputgmsg_name.gmsg from inputmd_name.md to .gmsg
export - Unpack inputgmsg_name.gmsg to .md

### How to use
```sh
luajit luigi.lua import inputgmsg_name inputmd_name outputgmsg_name
luajit luigi.lua export inputgmsg_name output_name
```

## Dependencies:
- luautf8
