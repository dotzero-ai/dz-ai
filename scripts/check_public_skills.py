#!/usr/bin/env python3
"""
公開 skill 的離線契約檢查（純本機、不連網、不讀任何憑證）。

為什麼要有這支：這個 repo 每次 push 前都要手動跑一輪 grep 與 diff
（見內部 backlog P3 的「推之前做的兩件事」），手動的東西遲早會漏。
六項檢查全部只讀檔案，所以可以直接掛進 GitHub Actions，
不需要任何 secret、不需要測試租戶。

**線上的「文件↔真 API 契約」驗證刻意不在這裡**——那需要租戶 token，
而公開 repo 的 Actions secret 會被 fork PR 讀走。那一層放在私有 repo。

用法：
    python3 scripts/check_public_skills.py
任何一項失敗就 exit 1。
"""

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# backlog 記載的原始 grep，一字不改。分成兩組是因為容忍度不同，不是把它放寬。
DENY = r"gitlab|10\.140\.|10\.28\.|internal\.|\.staging\."          # 零容忍
GUARDED = r"dotzerotech|localhost:50|password|secret|api[_-]?key"    # 有已知合法命中

# 每一條 GUARDED 命中都必須被下列其中一條吸收，否則算失敗。
ALLOW = [
    ("public-host", re.compile(r"dotzerotech[a-z0-9-]*\.dotzero\.app")),
    ("localhost-dev", re.compile(r"localhost:50\d\d")),
]
# password/secret/api_key 只在「沒有指派真值」時放行。這條抓的是
# `api_key: sk-xxxx` 這種，不是文件裡把 password 當名詞講的那 100 多行。
ASSIGNED_SECRET = re.compile(
    r"""(?i)(password|secret|api[_-]?key)\s*[:=]\s*["']?"""
    r"""(?!(your|my-|<|\$|\*|example|password|changeme|placeholder|xxx|null|true|false|string|none)\b)"""
    r"""[A-Za-z0-9+/=_.-]{8,}"""
)

LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
# 續行接起來再驗，不然 `claude mcp add foo \` 這種多行寫法看不到 `--`
MCP_ADD_RE = re.compile(r"claude mcp add\s+(.+)")

fails: list[str] = []


def report(ok: bool, msg: str) -> None:
    print(f"  {'OK  ' if ok else 'FAIL'} {msg}")
    if not ok:
        fails.append(msg)


def tracked_text_files() -> list[Path]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=REPO, capture_output=True, text=True, check=True
    ).stdout
    files = []
    for rel in out.split("\0"):
        if not rel:
            continue
        p = REPO / rel
        try:
            p.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue  # 二進位檔（目前沒有，但別讓它炸掉）
        files.append(p)
    return files


def check_copies_identical() -> None:
    print("[1/6] skills/ 與 skills-only/skills/ 位元組相同")
    r = subprocess.run(
        ["diff", "-r", "skills/", "skills-only/skills/"],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    if r.stdout or r.stderr:
        print(r.stdout + r.stderr, end="")
    report(r.returncode == 0, f"diff -r 零輸出（exit={r.returncode}）")


def check_frontmatter() -> None:
    print("[2/6] SKILL.md frontmatter")
    skills = sorted(
        set(REPO.glob("skills/*/SKILL.md")) | set(REPO.glob("skills-only/skills/*/SKILL.md"))
    )
    for md in skills:
        rel = md.relative_to(REPO)
        text = md.read_text(encoding="utf-8")
        if not text.startswith("---\n") or "\n---\n" not in text:
            report(False, f"{rel}: 缺 frontmatter 分隔線")
            continue
        fm = text.split("\n---\n", 1)[0][4:]
        # 只驗 Claude Code 真的會讀的兩個鍵，不引 PyYAML（公開 repo 目前零 Python 依賴）
        keys = dict(
            re.findall(r"^([a-z_]+):\s*(.*)$", fm, re.M)
        )
        problems = []
        if keys.get("name") != md.parent.name:
            problems.append(f"name={keys.get('name')!r} != 目錄名 {md.parent.name!r}")
        desc = keys.get("description", "").strip()
        if not desc:
            problems.append("description 空白")
        elif len(desc) > 1024:
            problems.append(f"description {len(desc)} 字元 > 1024")
        report(not problems, f"{rel}: " + ("; ".join(problems) or "name/description 有效"))
    print(f"  → 檢查了 {len(skills)} 支 SKILL.md")


def check_links() -> None:
    print("[3/6] skills/ 內部相對連結")
    checked = 0
    for md in sorted(REPO.glob("skills*/**/*.md")):
        for m in LINK_RE.finditer(md.read_text(encoding="utf-8")):
            target = m.group(1)
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            path_part = target.split("#", 1)[0]
            if not path_part:
                continue
            checked += 1
            resolved = (md.parent / path_part).resolve()
            report(
                resolved.exists(),
                f"{md.relative_to(REPO)} -> {target}"
                + ("" if resolved.exists() else "  (檔案不存在)"),
            )
    print(f"  → 檢查了 {checked} 條相對連結")


def check_secrets() -> None:
    print("[4/6] 機密與內部位址掃描")
    deny_re = re.compile(DENY, re.I)
    guarded_re = re.compile(GUARDED, re.I)
    scanned = hits = 0
    absorbed: dict[str, int] = {}
    residue: list[str] = []
    for p in tracked_text_files():
        if p.resolve() == Path(__file__).resolve():
            continue  # 這支腳本自己就寫著那串 pattern
        scanned += 1
        for n, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            loc = f"{p.relative_to(REPO)}:{n}"
            if deny_re.search(line):
                hits += 1
                residue.append(f"{loc}  [DENY] {line.strip()[:120]}")
                continue
            if not guarded_re.search(line):
                continue
            hits += 1
            # ⚠ ASSIGNED_SECRET 一定要在 ALLOW 之前判，而且**不能被 ALLOW 吸收**。
            # 原本寫成 `for ALLOW ... break / else: if ASSIGNED_SECRET`（for-else），
            # 意思變成「只要這一行有出現允許的 host 就整行放行」——而這批文件的 curl 範例
            # 每一條都打 dotzerotech*.dotzero.app 或 localhost:50xx，等於把風險最高的
            # 那批行整批豁免。實測：`curl -H "api_key: sk-...RealKey" https://dotzerotech-user-api.dotzero.app/...`
            # 這一行舊版完全不會報。允許的是「host 長這樣」，不是「這一行怎樣都行」。
            if ASSIGNED_SECRET.search(line):
                residue.append(f"{loc}  [SECRET] {line.strip()[:120]}")
                continue
            for label, rx in ALLOW:
                if rx.search(line):
                    absorbed[label] = absorbed.get(label, 0) + 1
                    break
            else:
                absorbed["prose-mention"] = absorbed.get("prose-mention", 0) + 1
    for line in residue:
        print(f"       {line}")
    report(not residue, f"{len(residue)} 條未列入允許的命中")
    npat = len(DENY.split("|")) + len(GUARDED.split("|"))
    print(
        f"  → 掃了 {scanned} 個追蹤中的文字檔、{npat} 條 grep pattern、{hits} 個命中；"
        f"已知允許：{absorbed}"
    )


def check_manifest_stats() -> None:
    """manifest 裡手抄的數字對帳。只查**離線就能算出真值**的那些。

    這裡的每一條都曾經真的漂移過（2026-08-07 一次抓到三條：skills 寫 10、totalTools 寫 217、
    longDescription 寫「7 MCP servers」）。`scripts/sync-public.sh` 從來不碰 stats
    （`grep -c stats` = 0），所以沒有這道檢查它只會越漂越遠。

    **totalTools 刻意不檢查**：真值要數各 MCP 套件的原始碼（權威腳本在私有 repo 的
    `scripts/count_mcp_tools.py`），離線算不出來。這支要能在公開 repo 的 CI 裸跑，
    寧可少查一項也不要引一個查不到的相依。
    """
    print("[5/6] marketplace manifest 手抄數字")
    mf = json.loads((REPO / ".claude-plugin/marketplace.json").read_text())
    actual = len(list(REPO.glob("skills/*/SKILL.md")))
    report(mf["stats"]["skills"] == actual,
           f'stats.skills={mf["stats"]["skills"]}，實際 skills/ 有 {actual} 支')

    n_srv = len(json.loads((REPO / ".mcp.json").read_text())["mcpServers"])
    blob = json.dumps(mf, ensure_ascii=False)
    claimed = re.findall(r"(\d+) MCP servers", blob)
    report(claimed and all(int(c) == n_srv for c in claimed),
           f'文案宣稱 {claimed or "（沒寫）"} 個 MCP server，.mcp.json 實際 {n_srv} 個')


def check_mcp_add_syntax() -> None:
    print("[6/6] claude mcp add 語法")
    checked = 0
    for p in tracked_text_files():
        if p.resolve() == Path(__file__).resolve():
            continue
        text = p.read_text(encoding="utf-8").replace("\\\n", " ")
        for n, line in enumerate(text.splitlines(), 1):
            m = MCP_ADD_RE.search(line)
            if not m:
                continue
            checked += 1
            rest = m.group(1)
            bad = []
            if "--command" in rest or "--args" in rest:
                bad.append("用了不存在的 --command/--args")
            if " -- " not in rest and not rest.rstrip().endswith(" --"):
                bad.append("缺 `--` 分隔（正確：claude mcp add <name> [-e K=V] -- <cmd> [args]）")
            report(not bad, f"{p.relative_to(REPO)}:{n} " + ("; ".join(bad) or "語法正確"))
    print(f"  → 檢查了 {checked} 條 claude mcp add")


def main() -> int:
    print("公開 skill 離線檢查（不連網、不讀憑證）\n")
    for fn in (
        check_copies_identical,
        check_frontmatter,
        check_links,
        check_secrets,
        check_manifest_stats,
        check_mcp_add_syntax,
    ):
        fn()
        print()
    if fails:
        print(f"✗ {len(fails)} 項失敗：")
        for f in fails:
            print(f"    - {f}")
        return 1
    print("✓ 全部通過")
    return 0


if __name__ == "__main__":
    sys.exit(main())
