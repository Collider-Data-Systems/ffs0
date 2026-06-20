#!/usr/bin/env python3
"""Fetch all notes from a *personal* (consumer) Google account's Keep and write
them as Markdown into a mirror directory.

Personal gmail has no official Keep API, so this uses the unofficial `gkeepapi`
(https://github.com/kiwiz/gkeepapi) with a **master token**. Treat that token
like a password: it lives in secrets/keep_personal.env (gitignored), never here.

This is the personal-account half of the Keep -> Drive mirror. The Workspace
account half goes through the existing official-API path
(dev/scripts/google_keep_fetch.jl via Invoke-KeepIngestHarness.ps1). Both halves
write Markdown into one mirror root which is then synced to Drive, so every
device (Android Drive app, Claude Desktop's Drive MCP, this session) can read it.

Usage:
    python3 keep_personal_fetch.py --out scratch/keep/mirror/personal
    # reads KEEP_EMAIL and KEEP_MASTER_TOKEN from the environment
    # (load them from secrets/keep_personal.env first)

Exit codes: 0 ok, 2 missing creds, 3 gkeepapi missing, 4 auth/sync failure.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime


def log(msg: str) -> None:
    print(f"[keep-personal] {msg}", file=sys.stderr)


def safe_slug(text: str, fallback: str) -> str:
    text = (text or "").strip().splitlines()[0] if text else ""
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", text).strip("-").lower()
    return (slug[:60] or fallback)


def ts(value) -> str:
    """gkeepapi timestamps are datetimes; render ISO, tolerate None/str."""
    if isinstance(value, datetime):
        return value.replace(microsecond=0).isoformat()
    return str(value or "")


def render_note(note) -> tuple[str, dict]:
    """Return (markdown, index_record) for one Keep note or list."""
    labels = []
    try:
        labels = [lbl.name for lbl in note.labels.all()]
    except Exception:
        pass

    created = ts(getattr(note.timestamps, "created", ""))
    updated = ts(getattr(note.timestamps, "updated", ""))

    # A checklist (gkeepapi List) renders as task items; a plain Note uses .text.
    body = ""
    items = getattr(note, "items", None)
    if items:
        body = "\n".join(
            f"- [{'x' if getattr(it, 'checked', False) else ' '}] {getattr(it, 'text', '')}"
            for it in items
        )
    else:
        body = getattr(note, "text", "") or ""

    title = getattr(note, "title", "") or ""
    front = {
        "id": getattr(note, "id", ""),
        "title": title,
        "created": created,
        "updated": updated,
        "archived": bool(getattr(note, "archived", False)),
        "pinned": bool(getattr(note, "pinned", False)),
        "color": str(getattr(note, "color", "")),
        "labels": labels,
        "source": "google-keep:personal",
    }
    fm = "\n".join(f"{k}: {json.dumps(v) if isinstance(v, (list, dict)) else v}" for k, v in front.items())
    md = f"---\n{fm}\n---\n\n# {title}\n\n{body}\n"
    return md, front


def main() -> int:
    ap = argparse.ArgumentParser(description="Mirror personal Google Keep notes to Markdown.")
    ap.add_argument("--out", default="scratch/keep/mirror/personal", help="Output directory.")
    ap.add_argument("--email", default=os.environ.get("KEEP_EMAIL", ""), help="Account email (or KEEP_EMAIL).")
    ap.add_argument("--exclude-archived", action="store_true",
                    help="Skip archived notes (default: include them).")
    args = ap.parse_args()

    email = args.email
    token = os.environ.get("KEEP_MASTER_TOKEN", "")
    if not email or not token:
        log("missing KEEP_EMAIL / KEEP_MASTER_TOKEN (load secrets/keep_personal.env first)")
        return 2

    try:
        import gkeepapi  # type: ignore
    except ImportError:
        log("gkeepapi not installed — run: pip install gkeepapi")
        return 3

    keep = gkeepapi.Keep()
    try:
        # Newer gkeepapi uses resume(email, master_token); older used authenticate().
        if hasattr(keep, "resume"):
            keep.resume(email, token)
        else:  # pragma: no cover - legacy path
            keep.authenticate(email, token)
        keep.sync()
    except Exception as exc:  # noqa: BLE001 - surface any auth/sync failure
        log(f"auth/sync failed: {exc}")
        return 4

    os.makedirs(args.out, exist_ok=True)
    index = []
    count = 0
    for note in keep.all():
        if getattr(note, "trashed", False):
            continue
        if getattr(note, "archived", False) and args.exclude_archived:
            continue
        md, rec = render_note(note)
        # Include a short note-ID suffix so notes that share a title+date don't collide.
        date = (rec["updated"] or rec["created"] or "")[:10]
        note_id = re.sub(r"[^A-Za-z0-9]+", "", rec["id"])[-8:] or "note"
        name = f"{date}_{safe_slug(rec['title'], note_id)}_{note_id}.md"
        with open(os.path.join(args.out, name), "w", encoding="utf-8") as fh:
            fh.write(md)
        rec["file"] = name
        index.append(rec)
        count += 1

    with open(os.path.join(args.out, "_index.json"), "w", encoding="utf-8") as fh:
        json.dump({"fetched_at": datetime.utcnow().isoformat() + "Z", "count": count, "notes": index}, fh, indent=2)

    log(f"wrote {count} notes to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
