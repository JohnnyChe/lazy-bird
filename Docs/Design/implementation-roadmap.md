# Quick Implementation Roadmap

## ⚠️ IMPORTANT: Updated for Corrected Architecture

This roadmap reflects the **corrected architecture**:
- **Phase 0 validation is MANDATORY first step**
- Uses actual Claude Code CLI commands (`claude -p`, not fictional `--task`)
- GitHub/GitLab Issues (not task files)
- Godot Server for test coordination
- gdUnit4 test framework
- Wizard-first installation approach

## 🧙 START HERE: Setup Wizard (Recommended)

### One Command Setup
```bash
# Run the wizard - it handles everything including Phase 0
curl -L https://raw.githubusercontent.com/yusyus/lazy_birtd/main/wizard.sh | bash

# Or if you prefer to review first
wget https://raw.githubusercontent.com/yusyus/lazy_birtd/main/wizard.sh
cat wizard.sh  # Review the script
bash wizard.sh
```

### What the Wizard Does For You
1. **Validates** your system with Phase 0 tests (REQUIRED)
2. **Detects** system capabilities (RAM, Godot, Claude, Git)
3. **Asks** 8 simple questions about your needs
4. **Recommends** the right phase to start
5. **Installs** everything automatically (services, scripts, configs)
6. **Secures** API tokens in proper locations
7. **Runs** a test task to verify everything works
8. **Monitors** and helps you upgrade later

### Wizard's 8 Questions
The wizard will ask you these questions to determine your setup:

1. **Godot project path?** - Where your game project is located
2. **GitHub or GitLab?** - Which platform for issues/PRs
3. **API token configured?** - Checks if you have access configured
4. **Target phase?** - Or let wizard recommend based on system
5. **RAM limit?** - How much RAM to allocate (8-16GB typical)
6. **Docker available?** - Needed for Phase 3+ features
7. **Remote access needed?** - VPN and dashboard (Phase 3)
8. **Confirm installation?** - Final check before proceeding

### Typical Answers for Solo Dev (16GB RAM)
```
1. Godot project: /home/user/my-godot-game
2. Platform: GitHub
3. Token: Yes (stored in ~/.config/lazy_birtd/secrets/)
4. Phase: 1 (wizard will recommend this to start)
5. RAM limit: 10GB (leaves 6GB for system)
6. Docker: No initially (can add later)
7. Remote: Not yet (Phase 3 feature)
8. Confirm: Yes
```

---

## ✅ Phase 0: Validation (REQUIRED FIRST - 15-30 min)

**YOU MUST complete Phase 0 before any implementation.**

### What Phase 0 Does
Validates all assumptions before building anything:
- Claude Code CLI exists and uses correct syntax
- Godot 4.x with headless mode works
- gdUnit4 test framework installed
- Git worktrees functional
- GitHub/GitLab API access configured
- Required permissions and directories

### Run Phase 0 Validation
```bash
# Clone the repo
git clone https://github.com/yusyus/lazy_birtd.git
cd lazy_birtd

# Run comprehensive validation
./tests/phase0/validate-all.sh /path/to/your/godot-project

# Expected output:
✓ Claude Code CLI found
✓ Correct flags available
✓ Godot 4.x headless mode works
✓ gdUnit4 installed and functional
✓ Git worktrees operational
✓ API access configured
✅ VALIDATION PASSED
```

### If Validation Fails
The validation scripts will tell you exactly what to fix:

```bash
# Individual validation scripts available:
./scripts/validate-claude.sh          # Test Claude Code CLI
./scripts/validate-godot.sh <project> # Test Godot + gdUnit4
./scripts/test-worktree.sh <project>  # Test git worktrees
```

**DO NOT proceed to Phase 1 until all Phase 0 tests pass!**

---

## 🚀 Manual Start (If Not Using Wizard)

```
Q: How much time do you have this weekend?
├─ Less than 2 hours → Phase 1 Basic Script
├─ Full weekend → Phase 1 + 2 (Git isolation)
└─ Already automated → Jump to Phase 3

Q: What's your RAM?
├─ 8GB → Max Phase 2 (single agent)
├─ 16GB → Max Phase 4 (2-3 agents)  👈 You are here
└─ 32GB+ → Can do Phase 6

Q: Your biggest pain point?
├─ "I waste evenings on repetitive tasks" → Phase 1
├─ "My git history is messy" → Phase 2
├─ "I can't check progress at work" → Phase 3
└─ "Development is too slow" → Phase 4
```

---

## ⚡ Phase 1: GitHub Issues Automation (15 min with wizard, 2 hours manual)

**Prerequisites:**
- ✅ Phase 0 validation passed
- ✅ GitHub/GitLab account with API token
- ✅ Claude Code CLI working

### Option A: Wizard (Recommended - 15 min)
```bash
./wizard.sh
# Answer 8 questions, wizard installs everything
```

### Option B: Manual Setup (2 hours)

#### Hour 1: Install Issue Watcher Service
```bash
# 1. Install dependencies
pip3 install pygithub  # or python-gitlab

# 2. Create configuration directory
mkdir -p ~/.config/lazy_birtd/secrets
chmod 700 ~/.config/lazy_birtd/secrets

# 3. Store GitHub token securely
echo "YOUR_GITHUB_TOKEN_HERE" > ~/.config/lazy_birtd/secrets/github_token
chmod 600 ~/.config/lazy_birtd/secrets/github_token

# 4. Create agent runner script
cat > ~/lazy_birtd/agent-runner.sh << 'EOF'
#!/bin/bash
ISSUE_ID=$1
ISSUE_TITLE=$2
ISSUE_BODY=$3

PROJECT_ROOT="/home/user/godot-game"
WORKTREE="/tmp/agent-${ISSUE_ID}"
BRANCH="feature-${ISSUE_ID}"

cd "$PROJECT_ROOT"
git worktree add -b "$BRANCH" "$WORKTREE"
cd "$WORKTREE"

# Run Claude Code (CORRECT SYNTAX)
claude -p "$(cat <<PROMPT
TASK: $ISSUE_TITLE

DETAILS:
$ISSUE_BODY

Implement this feature. Commit your changes when done.
PROMPT
)" > /tmp/agent-${ISSUE_ID}.log 2>&1

# Create PR if changes made
if ! git diff --quiet; then
    git add .
    git commit -m "Implement: $ISSUE_TITLE"
    git push origin "$BRANCH"

    gh pr create \
        --title "Auto PR #${ISSUE_ID}: ${ISSUE_TITLE}" \
        --body "Automated implementation" \
        --base main \
        --head "$BRANCH"
fi

cd / && git worktree remove "$WORKTREE" --force
EOF

chmod +x ~/lazy_birtd/agent-runner.sh

# 5. Create issue watcher service
cat > ~/.config/systemd/user/issue-watcher.service << 'EOF'
[Unit]
Description=GitHub Issue Watcher for Lazy_Birtd
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/user/lazy_birtd/scripts/issue-watcher.py
Restart=always
RestartSec=60

[Install]
WantedBy=default.target
EOF

systemctl --user enable issue-watcher
systemctl --user start issue-watcher
```

#### Hour 2: Create Your First Task
```bash
# Create a GitHub Issue with the "ready" label
gh issue create \
  --title "[Task]: Add player health bar" \
  --body "$(cat <<EOF
## Task Description
Add a simple health bar UI to the player

## Detailed Steps
1. Create res://ui/health_bar.gd
2. Extend Control or ProgressBar
3. Add @export var max_health = 100
4. Add update_health(current, max) method
5. Connect to player health signal

## Acceptance Criteria
- [ ] Health bar appears in top-left corner
- [ ] Updates when player takes damage
- [ ] Tests pass
EOF
)" \
  --label "ready"

# Monitor the automation
journalctl --user -u issue-watcher -f
```

### Success Criteria
- [ ] Issue watcher service running
- [ ] Created issue gets picked up automatically
- [ ] Agent creates PR with implementation
- [ ] You can review PR on GitHub
- [ ] You saved 2+ hours this week

---

## 📈 Phase 2: Next Weekend (Git Isolation)

### Prerequisites Complete
- [ ] Phase 1 working for a week
- [ ] Comfortable with git branches
- [ ] Ready for cleaner workflow

### Setup Gitea (1 hour)
```bash
# Quick Docker install on Manjaro
sudo pacman -S docker docker-compose
sudo systemctl start docker
sudo usermod -aG docker $USER

# Gitea setup
mkdir gitea && cd gitea
cat > docker-compose.yml << EOF
version: "3"
services:
  gitea:
    image: gitea/gitea:latest
    ports:
      - "3000:3000"
    volumes:
      - ./data:/data
    environment:
      - USER_UID=1000
      - USER_GID=1000
EOF

docker-compose up -d

# Access at http://localhost:3000
# First login creates admin account
```

### Worktree Automation (1 hour)
```bash
# Enhanced script with branches
cat > process-v2.sh << 'EOF'
#!/bin/bash
process_task() {
    TASK_ID=$1
    TASK_DESC=$2
    BRANCH="feature-${TASK_ID}"
    WORKTREE="/tmp/agent-${TASK_ID}"
    
    git worktree add -b $BRANCH $WORKTREE
    cd $WORKTREE
    
    claude-code --task "$TASK_DESC"
    
    # Simple test
    if godot --headless --quit --check-only; then
        git push origin $BRANCH
        echo "✅ Ready: $BRANCH"
        # Create PR via Gitea API
        curl -X POST "http://localhost:3000/api/v1/repos/game/pulls" \
             -H "Content-Type: application/json" \
             -d "{\"title\":\"$TASK_DESC\",\"head\":\"$BRANCH\",\"base\":\"main\"}"
    fi
    
    cd / && git worktree remove $WORKTREE --force
}

# Example usage
process_task "001" "Add double jump mechanic"
EOF
```

---

## 🌐 Phase 3: Week 3 (Remote Access)

### WireGuard VPN (30 min)
```bash
# Install WireGuard
sudo pacman -S wireguard-tools

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Server config
sudo cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat privatekey)

[Peer]
# Your phone/laptop
PublicKey = [phone public key]
AllowedIPs = 10.0.0.2/32
EOF

sudo systemctl enable --now wg-quick@wg0
```

### Web Dashboard (1 hour)
```python
# dashboard.py - Simple Flask monitoring
from flask import Flask, render_template
import json, subprocess

app = Flask(__name__)

@app.route('/')
def home():
    tasks = json.load(open('tasks.json'))
    active = len(subprocess.check_output(['pgrep', 'claude-code']).split())
    return f"""
    <h1>Game Dev Automation</h1>
    <p>Pending Tasks: {len(tasks)}</p>
    <p>Active Agents: {active}</p>
    <pre>{json.dumps(tasks, indent=2)}</pre>
    """

app.run(host='0.0.0.0', port=5000)
```

### Mobile Notifications
```bash
# Add to any script
notify() {
    curl -d "$1" https://ntfy.sh/your-unique-topic
}

# In automation script
notify "✅ Task complete: $TASK_DESC"
```

---

## 🚄 Phase 4: Month 2 (Multi-Agent)

### Only If Needed
- [ ] You have 10+ tasks daily
- [ ] Single agent too slow
- [ ] RAM usage under 10GB normally

### Smart Scheduler
```python
# scheduler.py - Minimal version
import json, time, subprocess, psutil

def can_run_agent():
    # Check if we have 4GB free
    return psutil.virtual_memory().available > 4*1024**3

def launch_agent(task):
    if can_run_agent():
        subprocess.Popen(['./process-v2.sh', task['id'], task['desc']])
        return True
    return False

while True:
    tasks = json.load(open('tasks.json'))
    for task in tasks[:3]:  # Max 3 agents
        if launch_agent(task):
            tasks.remove(task)
            time.sleep(30)
    json.dump(tasks, open('tasks.json', 'w'))
    time.sleep(300)
```

---

## 📊 Progress Tracking

### Week 1 Metrics
```bash
# Add to your automation
echo "$(date),${TASK},${DURATION}" >> metrics.csv

# Weekly review
echo "Tasks completed this week:"
grep "$(date -d '7 days ago' +%Y-%m-%d)..$(date +%Y-%m-%d)" metrics.csv | wc -l
```

### Month 1 Review Checklist
- [ ] Hours saved: _____ (target: 20+)
- [ ] Tasks automated: _____ (target: 50+)
- [ ] PRs merged: _____ (target: 30+)
- [ ] Ready for next phase? Y/N

---

## 🆘 Troubleshooting

### Claude Code Issues
```bash
# Check if Claude is working
claude-code --version

# Test with simple task
claude-code --task "Add a comment saying hello world"

# Check API limits
curl -H "Authorization: Bearer $CLAUDE_API_KEY" \
     https://api.anthropic.com/v1/rate_limits
```

### Git Worktree Conflicts
```bash
# Clean up broken worktrees
git worktree prune

# Force remove stuck worktree
rm -rf /tmp/agent-*
git worktree prune
```

### High RAM Usage
```bash
# Emergency kill all agents
pkill -f claude-code

# Check what's using RAM
ps aux --sort=-%mem | head

# Limit future agents
systemd-run --scope -p MemoryLimit=2G claude-code --task "..."
```

---

## 🎯 Success Milestones

### End of Week 1
- ✅ 5+ tasks completed automatically
- ✅ You didn't touch repetitive code
- ✅ More time for creative work

### End of Month 1
- ✅ 50+ automated tasks done
- ✅ Git history clean with branches
- ✅ Can manage from phone

### End of Month 3
- ✅ 200+ tasks automated
- ✅ Development speed doubled
- ✅ More game, less grind

---

## 💭 Remember

1. **Start Today** - Phase 1 takes 2 hours
2. **Perfect < Working** - Simple automation beats plans
3. **Iterate Weekly** - Small improvements compound
4. **Measure Everything** - Data drives decisions
5. **Share Progress** - Blog/tweet your setup

---

## 📞 Next Actions (Updated for Corrected Architecture)

### Right Now (5 min)
```bash
# 1. Check Claude Code is installed
claude --version  # Note: 'claude' not 'claude-code'

# 2. Clone Lazy_Birtd repo
git clone https://github.com/yusyus/lazy_birtd.git
cd lazy_birtd

# 3. Run Phase 0 validation (REQUIRED)
./tests/phase0/validate-all.sh /path/to/your/godot-project

# 4. If validation passes, run wizard
./wizard.sh

# 5. Follow wizard prompts (8 questions)
```

### After Wizard Setup (5 min)
```bash
# 1. Create your first automated task (GitHub Issue)
gh issue create --template task \
  --title "[Task]: Add player health bar UI" \
  --label "ready"

# 2. Monitor progress
journalctl --user -u issue-watcher -f

# Or check wizard status
./wizard.sh --status
```

### Tonight (30 min)
- Create 3-5 GitHub Issues for tomorrow
- Label them with "ready"
- Let automation run overnight
- Check PRs in the morning

### This Weekend (2 hours)
- Review first week's results
- Adjust task descriptions for better results
- Consider upgrading to Phase 2 (Godot Server + testing)

### Week 2+
```bash
# Weekly review
./wizard.sh --weekly-review

# Upgrade when ready
./wizard.sh --upgrade
```

---

**The journey of 1000 automated tasks begins with Phase 0 validation.**

✅ Validate → 🧙 Wizard → 📝 GitHub Issues → 🤖 Automation → 🎮 More Game Dev

Start now. Review tonight. Iterate tomorrow.