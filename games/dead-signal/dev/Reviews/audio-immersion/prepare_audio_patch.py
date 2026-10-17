"""Compose a reviewed audio proposal without editing runtime source.

An integrator may apply the emitted patch after recording the scoped grant in #23.
No ModuleScript, native asset, caller, config, workflow or test runner is added.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
from pathlib import Path

DEV = Path(__file__).resolve().parents[2]
RUNTIME = DEV / "Source/Runtime/client/Effects.lua"
PROPOSAL = Path(__file__).with_name("Effects-audio.luau")
ORIGINAL_BLOCK_SHA256 = "5e37e02ca49c0b8a39d005778cc26b2639c8d1e7b2912cfce9576a0cf063936a"
TICK = "function FX:animate(dt)\n"
NEW_TICK = TICK + "    self:audioUpdate(dt)\n"


def compose(source: str, proposal: str) -> str:
    """Refuse concurrent audio edits; preserve every byte outside two audio sites."""
    start = source.index("local stock=")
    end = source.index("function FX:part(")
    block = source[start:end]
    if hashlib.sha256(block.encode()).hexdigest() != ORIGINAL_BLOCK_SHA256:
        raise ValueError("Effects audio block changed; re-review ownership and patch")
    if source.count(TICK) != 1 or "self:audioUpdate(dt)" in source:
        raise ValueError("Effects audio tick changed or was already applied")
    result = source[:start] + proposal.rstrip() + "\n" + source[end:]
    return result.replace(TICK, NEW_TICK, 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Write proposed unified patch here")
    parser.add_argument("--candidate", type=Path, help="Write an offline Effects source copy here")
    args = parser.parse_args()
    source = RUNTIME.read_text()
    proposed = compose(source, PROPOSAL.read_text())
    relative = "games/dead-signal/dev/Source/Runtime/client/Effects.lua"
    patch = "".join(difflib.unified_diff(source.splitlines(True), proposed.splitlines(True),
                                        fromfile="a/" + relative, tofile="b/" + relative))
    for target in (args.output, args.candidate):
        if target and target.resolve() == RUNTIME.resolve():
            raise ValueError("This proposal tool never writes to runtime Effects.lua")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(patch)
    if args.candidate:
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_text(proposed)
    print("Proposal composes; runtime untouched; candidate SHA256:", hashlib.sha256(proposed.encode()).hexdigest())


if __name__ == "__main__":
    main()
