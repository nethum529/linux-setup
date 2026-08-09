function danger
    # Pre-accept the folder-trust dialog for $PWD so --dangerously-skip-permissions
    # launches don't prompt. Scoped to `danger`; plain `claude` elsewhere is unaffected.
    if test -f ~/.claude.json
        python3 -c '
import json, os, tempfile
cfg = os.path.expanduser("~/.claude.json")
with open(cfg) as f: d = json.load(f)
d.setdefault("projects", {}).setdefault(os.getcwd(), {})["hasTrustDialogAccepted"] = True
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(cfg), prefix=".claude.json.")
with os.fdopen(fd, "w") as f: json.dump(d, f, indent=2)
os.replace(tmp, cfg)
' 2>/dev/null
    end
    claude --dangerously-skip-permissions $argv
end
