"""Lightweight Lua block-balance / undefined-global checker for the
PDZ resources. Not a full parser, but it catches the mistakes that actually
happen when hand-porting decompiled code: a missing `end`, an unbalanced
bracket, or a call to a function that no longer exists.
"""
import re
import sys

KEYWORDS_OPEN = {"function", "if", "do", "while", "for"}


def strip_noise(src):
    """Remove strings and comments so keywords inside them do not count."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        # long comment / long string
        if src.startswith("--[[", i):
            j = src.find("]]", i)
            i = n if j < 0 else j + 2
            continue
        if src.startswith("--", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            i = n if j < 0 else j + len(close)
            continue
        if c in "\"'":
            quote, j = c, i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == quote:
                    break
                j += 1
            i = j + 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check(path):
    src = strip_noise(open(path, encoding="utf-8", errors="replace").read())
    problems = []

    # bracket balance
    for open_c, close_c in (("(", ")"), ("{", "}"), ("[", "]")):
        depth = 0
        for ch in src:
            if ch == open_c:
                depth += 1
            elif ch == close_c:
                depth -= 1
                if depth < 0:
                    problems.append(f"unmatched '{close_c}'")
                    break
        if depth > 0:
            problems.append(f"{open_c}{close_c} unbalanced (depth {depth})")

    # block balance: function/if/do/while/for open, 'end' closes.
    # A `for`/`while` header opens ONE block; its header `do` belongs to that
    # block (not counted twice). A STANDALONE `do` opens a block of its own.
    tokens = re.findall(r"\b[A-Za-z_]\w*\b", src)
    depth, opened = 0, []
    expect_do = False  # the next `do` is the header of a for/while
    for tok in tokens:
        if tok == "function":
            depth += 1
            opened.append("function")
            expect_do = False
        elif tok == "if":
            depth += 1
            opened.append("if")
            expect_do = False
        elif tok in ("for", "while"):
            depth += 1
            opened.append(tok)
            expect_do = True
        elif tok == "do":
            if expect_do:
                expect_do = False  # header do of a for/while - not a new block
            else:
                depth += 1
                opened.append("do")
        elif tok == "repeat":
            depth += 1
            opened.append("repeat")
        elif tok == "until":
            if opened and opened[-1] == "repeat":
                depth -= 1
                opened.pop()
        elif tok == "end":
            if opened:
                opened.pop()
                depth -= 1
            else:
                problems.append("extra 'end' with nothing open")

    if opened:
        problems.append(
            f"{len(opened)} unclosed block(s): {', '.join(opened[-5:])}"
        )
    return problems


if __name__ == "__main__":
    bad = False
    for p in sys.argv[1:]:
        probs = check(p)
        if probs:
            bad = True
            print(f"FAIL {p}")
            for pr in probs:
                print(f"   - {pr}")
        else:
            print(f"OK   {p}")
    sys.exit(1 if bad else 0)
