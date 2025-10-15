# Git Workflow for Two Development PCs

## Overview
This guide explains how to sync Mediabox development between your 4K PC and home development PC using Git.

## Repository
- **GitHub**: https://github.com/marknchristian/mediabox.git
- **4K PC**: `C:\@Code\Mediabox\mediabox\`
- **Home PC**: Clone the same repository

## Daily Workflow

### When Starting Work (on either PC):
```bash
# 1. Pull latest changes from GitHub
git pull origin master

# 2. Install/update dependencies if needed
npm install
```

### When Making Changes:
```bash
# 1. Make your changes to the code
# 2. Test the changes
npm run dev

# 3. Stage your changes
git add .

# 4. Commit with descriptive message
git commit -m "feat: description of what you changed"

# 5. Push to GitHub
git push origin master
```

### When Switching PCs:
```bash
# Always pull before starting work
git pull origin master
```

## Common Commands

### Check Status:
```bash
git status                    # See what files changed
git log --oneline -5         # See recent commits
git diff                     # See what changed
```

### Undo Changes:
```bash
git restore <filename>       # Undo changes to a file
git reset --hard HEAD        # Undo all local changes (DANGER!)
```

### Branching (Advanced):
```bash
git checkout -b feature-name  # Create new branch
git checkout master          # Switch back to main
git merge feature-name       # Merge branch into master
```

## Best Practices

1. **Always pull before starting work**
2. **Commit frequently with clear messages**
3. **Test changes before committing**
4. **Use descriptive commit messages**
5. **Keep commits small and focused**

## Commit Message Format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Code formatting
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

## Troubleshooting

### If you get merge conflicts:
```bash
git status                    # See conflicted files
# Edit files to resolve conflicts
git add .
git commit -m "resolve merge conflicts"
```

### If you accidentally commit to wrong branch:
```bash
git log --oneline -2         # Find commit hash
git reset --soft HEAD~1      # Undo last commit (keep changes)
git add .
git commit -m "corrected message"
```

## Setup for Home PC

1. Clone the repository:
```bash
git clone https://github.com/marknchristian/mediabox.git
cd mediabox
npm install
```

2. Configure Git (if not already done):
```bash
git config --global user.name "Mark Christian"
git config --global user.email "your-email@example.com"
```

3. Test the setup:
```bash
npm run dev
```
