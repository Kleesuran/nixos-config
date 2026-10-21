#!/usr/bin/env python3
# patchelf 会给 nvidia-smi 生成重叠的 PT_LOAD：.dynamic 同时落在
# 一个 RW 段和一个后映射的 R 段里，后映射的 R 段生效，ld.so 写
# DT_DEBUG（0x401488）时触发 SEGV_ACCERR。把最后映射的、覆盖
# PT_DYNAMIC 的 LOAD 段改成可写即可。
#
# 仅修改 ELF 程序头的 p_flags，不改代码；驱动布局正常时脚本不做任何事。
import struct
import sys

path = sys.argv[1]
data = bytearray(open(path, 'rb').read())

if data[:4] != b'\x7fELF' or data[4] != 2 or data[5] != 1:
    sys.exit('not a 64-bit little-endian ELF')

e_phoff = struct.unpack_from('<Q', data, 0x20)[0]
e_phentsize = struct.unpack_from('<H', data, 0x36)[0]
e_phnum = struct.unpack_from('<H', data, 0x38)[0]

phdrs = []
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_flags = struct.unpack_from('<II', data, off)
    p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from(
        '<QQQQQQ', data, off + 8
    )
    phdrs.append(
        {
            'i': i,
            'off': off,
            'type': p_type,
            'flags': p_flags,
            'vaddr': p_vaddr,
            'memsz': p_memsz,
        }
    )

dynamic = next((p for p in phdrs if p['type'] == 2), None)
if dynamic is None:
    sys.exit('no PT_DYNAMIC')

# 内核按程序头顺序建立映射，最后一个覆盖该地址的 PT_LOAD 决定权限。
winner = None
for p in phdrs:
    if p['type'] == 1 and p['vaddr'] <= dynamic['vaddr'] < p['vaddr'] + p['memsz']:
        winner = p

if winner is None:
    sys.exit('no PT_LOAD covers PT_DYNAMIC')

if winner['flags'] & 2:
    print(f"PT_LOAD #{winner['i']} already writable, nothing to do")
    sys.exit(0)

print(
    f"PT_LOAD #{winner['i']} vaddr=0x{winner['vaddr']:x} "
    f"flags={winner['flags']} -> writable"
)
struct.pack_into('<I', data, winner['off'] + 4, winner['flags'] | 2)
open(path, 'wb').write(data)
