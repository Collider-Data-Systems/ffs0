"""
Firestarter: classify-skill.py
Reads a SKILL.md file, extracts structured metadata, classifies against
the mo:os ontology, and outputs a JSON Program ready for POST /programs.

Usage: python classify-skill.py <path-to-skill-dir> [--root-urn <kernel-root>]

Output: JSON Program to stdout (pipe to curl or save to file).
"""

import json
import os
import re
import sys

FIRESTARTER_URN = "urn:moos:agent:firestarter"
DEFAULT_ROOT_URN = "urn:moos:kernel:wave-0"

# Skills that define agent behavior (OBJ21) rather than tool behavior (OBJ07)
AGENT_KEYWORDS = {"agent", "orchestrate", "compose", "delegate", "autonomous", "pipeline"}

# Skills that are reusable templates (OBJ04)
TEMPLATE_KEYWORDS = {"template", "scaffold", "boilerplate", "starter"}


def parse_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter from --- delimited block."""
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    fm = {}
    for line in match.group(1).strip().splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            fm[key.strip()] = val.strip()
    return fm


def extract_section(content: str, heading: str) -> str:
    """Extract text under a markdown heading (## or ###)."""
    pattern = r"^#{2,3}\s+" + re.escape(heading) + r"\s*\n(.*?)(?=\n#{2,3}\s|\Z)"
    match = re.search(pattern, content, re.MULTILINE | re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return ""


def extract_section_fuzzy(content: str, keywords: list[str]) -> str:
    """Find a section whose heading contains any of the keywords (case-insensitive)."""
    # Split into lines, find heading, capture until next heading
    lines = content.split("\n")
    for kw in keywords:
        kw_lower = kw.lower()
        for i, line in enumerate(lines):
            if re.match(r"^#{2,4}\s+", line) and kw_lower in line.lower():
                # Found heading, collect until next heading of same or higher level
                body_lines = []
                for j in range(i + 1, len(lines)):
                    if re.match(r"^#{2,4}\s+", lines[j]):
                        break
                    body_lines.append(lines[j])
                result = "\n".join(body_lines).strip()
                if result:
                    return result
    return ""


def extract_capabilities(content: str, name: str) -> list[str]:
    """Extract capability keywords from skill content."""
    caps = set()
    # From explicit capability/keyword sections
    cap_text = extract_section_fuzzy(content, ["capabilit", "keyword", "expertise", "features"])
    if cap_text:
        for line in cap_text.splitlines():
            line = line.strip().lstrip("-*").strip()
            if line and len(line) < 60:
                caps.add(line.lower().replace(" ", "-"))

    # From skill name
    for part in name.replace("_", "-").split("-"):
        if len(part) > 2:
            caps.add(part.lower())

    return sorted(caps)[:12]  # cap at 12 keywords


def extract_key_files(content: str) -> list[str]:
    """Extract file path references from the skill."""
    paths = set()
    # Match common path patterns
    for match in re.finditer(r'[`"]([a-zA-Z0-9_./-]+(?:\.(?:go|py|json|md|ts|js|yaml|toml))[a-zA-Z0-9_./-]*)[`"]', content):
        paths.add(match.group(1))
    # Match directory-style paths
    for match in re.finditer(r'[`"]((?:internal|platform|\.agent|superset|instances|kb)/[a-zA-Z0-9_./-]+)[`"]', content):
        paths.add(match.group(1))
    return sorted(paths)[:20]


def extract_dependencies(content: str, all_skills: list[str]) -> list[str]:
    """Find references to other skills in the content."""
    deps = []
    for skill in all_skills:
        if skill in content.lower():
            deps.append(skill)
    return deps


def classify_type(name: str, content: str) -> tuple[str, str]:
    """Classify a skill into an ontology type.
    Returns (type_id, obj_id)."""
    content_lower = content.lower()

    if any(kw in content_lower for kw in TEMPLATE_KEYWORDS):
        if "template" in name or "scaffold" in name:
            return "app_template", "OBJ04"

    if any(kw in content_lower for kw in AGENT_KEYWORDS):
        agent_score = sum(1 for kw in AGENT_KEYWORDS if kw in content_lower)
        if agent_score >= 2:
            return "agent_spec", "OBJ21"

    return "system_tool", "OBJ07"


def build_program(skill_dir: str, root_urn: str, mode: str = "add", expected_version: int = 1) -> dict:
    """Build a complete Program from a skill directory.
    mode: "add" = ADD+LINK (new nodes), "enrich" = MUTATE (existing nodes).
    expected_version: CAS version for MUTATE (default 1 = first mutation after hydration)."""
    skill_md_path = os.path.join(skill_dir, "SKILL.md")
    if not os.path.isfile(skill_md_path):
        raise FileNotFoundError(f"No SKILL.md in {skill_dir}")

    with open(skill_md_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # Parse frontmatter
    fm = parse_frontmatter(content)
    skill_name = fm.get("name", os.path.basename(skill_dir))
    skill_desc = fm.get("description", "")
    allowed_tools = fm.get("allowed-tools", "")

    # Extract structured fields from body
    when_to_use = extract_section_fuzzy(content, [
        "When to Use", "when to use", "Use When", "Activate when",
        "When This Skill", "Axioms", "Design Decision", "Usage",
    ])
    when_not_to_use = extract_section_fuzzy(content, [
        "When Not to Use", "when not to use", "Don't Use", "When NOT",
        "Anti-pattern", "anti-pattern", "Common Issues", "Error",
    ])
    capabilities = extract_capabilities(content, skill_name)
    key_files = extract_key_files(content)

    # Get sibling skill names for dependency detection
    parent_dir = os.path.dirname(skill_dir)
    all_skills = []
    if os.path.isdir(parent_dir):
        all_skills = [d for d in os.listdir(parent_dir)
                      if os.path.isdir(os.path.join(parent_dir, d)) and d != os.path.basename(skill_dir)]
    dependencies = extract_dependencies(content, all_skills)

    # Classify
    type_id, obj_id = classify_type(skill_name, content)
    urn = f"urn:moos:tool:{skill_name}" if type_id == "system_tool" else f"urn:moos:agent:{skill_name}" if type_id == "agent_spec" else f"urn:moos:template:{skill_name}"

    # Build payload (the metadata sticker)
    payload = {
        "name": skill_name,
        "description": skill_desc,
        "when_to_use": when_to_use[:500] if when_to_use else "",
        "when_not_to_use": when_not_to_use[:500] if when_not_to_use else "",
        "capabilities": capabilities,
        "skill_path": os.path.relpath(skill_md_path, os.path.join(skill_dir, "..", "..", "..")).replace("\\", "/"),
        "dependencies": dependencies,
        "key_files": key_files,
        "allowed_tools": allowed_tools,
        "source": f"ind:skill:{skill_name}",
        "classified_as": obj_id,
        "user_stars": 0,  # Human rating: 0=unrated, 1-5=rated. Only Sam mutates this.
    }

    # Build envelopes based on mode
    envelopes = []

    if mode == "enrich":
        # MUTATE existing node to add metadata payload.
        # expected_version: 1 for nodes hydrated once at boot.
        # If the node was mutated further, the caller needs --version.
        envelopes.append({
            "type": "MUTATE",
            "actor": FIRESTARTER_URN,
            "mutate": {
                "urn": urn,
                "expected_version": expected_version,
                "payload": payload,
                "metadata": {
                    "hydrated_by": "firestarter",
                    "skill_dir": os.path.basename(skill_dir),
                    "enriched": True,
                },
            },
        })
    else:
        # ADD new skill node
        envelopes.append({
            "type": "ADD",
            "actor": FIRESTARTER_URN,
            "add": {
                "urn": urn,
                "type_id": type_id,
                "stratum": "S2",
                "payload": payload,
                "metadata": {
                    "hydrated_by": "firestarter",
                    "skill_dir": os.path.basename(skill_dir),
                },
            },
        })

        # LINK: kernel root OWNS this tool
        envelopes.append({
            "type": "LINK",
            "actor": FIRESTARTER_URN,
            "link": {
                "source_urn": root_urn,
                "source_port": "owns",
                "target_urn": urn,
                "target_port": "child",
            },
        })

    return {
        "actor": FIRESTARTER_URN,
        "scope": root_urn,
        "envelopes": envelopes,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python classify-skill.py <skill-dir> [--root-urn <urn>] [--mode add|enrich]", file=sys.stderr)
        sys.exit(1)

    skill_dir = os.path.normpath(sys.argv[1])
    root_urn = DEFAULT_ROOT_URN
    mode = "add"

    if "--root-urn" in sys.argv:
        idx = sys.argv.index("--root-urn")
        if idx + 1 < len(sys.argv):
            root_urn = sys.argv[idx + 1]

    if "--mode" in sys.argv:
        idx = sys.argv.index("--mode")
        if idx + 1 < len(sys.argv):
            mode = sys.argv[idx + 1]

    expected_version = 1
    if "--version" in sys.argv:
        idx = sys.argv.index("--version")
        if idx + 1 < len(sys.argv):
            expected_version = int(sys.argv[idx + 1])

    try:
        program = build_program(skill_dir, root_urn, mode, expected_version)
        print(json.dumps(program, indent=2))
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
