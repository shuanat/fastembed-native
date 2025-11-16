# Branching Strategy

**Date**: 2025-11-15  
**Project**: FastEmbed Native Library  
**Status**: Active

---

## Overview

FastEmbed uses a simplified Git Flow strategy optimized for a multi-platform native library with multiple language bindings. This strategy ensures code quality, stability, and efficient release management.

---

## Branch Types

### 1. `master` - Stable Production Branch

**Purpose:**

- Contains only stable, production-ready code
- Always in a working state
- Represents the latest released version

**Protection:**

- Protected branch (requires PR)
- Requires code review approval
- Requires all CI checks to pass
- Only accepts merges from `release/*` branches

**Workflow:**

- ✅ CI tests run on every push and PR
- ✅ Build verification
- ❌ Does NOT create artifacts (only tags trigger artifacts)
- ❌ Does NOT create releases (only tags trigger releases)

**When to use:**

- Final destination for release branches
- Source for creating version tags
- Reference for production deployments

---

### 2. `release/*` - Release Preparation Branches

**Purpose:**

- Prepare and test releases before merging to master
- Collect features for a specific version
- Final testing and validation

**Naming Convention:**

- `release/1.0.1` - Version-based naming
- `release/1.0.2` - Next version

**Workflow:**

- ✅ CI tests run on every push and PR
- ✅ Build verification
- ✅ Preview artifacts (optional, GitHub Actions artifacts, 7 days retention)
- ❌ Does NOT create final releases
- ❌ Does NOT publish to npm/PyPI/NuGet/Maven

**When to use:**

- Collecting features for a release
- Final testing before production
- Preparing release notes

**Protection:**

- Protected branch (requires PR)
- Requires code review approval
- Requires all CI checks to pass
- Accepts PRs from `feature/*` branches

---

### 3. `feature/*` - Feature Development Branches

**Purpose:**

- Develop new features
- Fix bugs
- Experiment with new approaches

**Naming Convention:**

- `feature/arm64-neon-implementation`
- `feature/java-jar-build-fixes`
- `feature/onnx-runtime-support`

**Workflow:**

- ✅ CI tests run on PR
- ✅ Build verification
- ❌ Does NOT create artifacts
- ❌ Does NOT create releases

**When to use:**

- Developing new functionality
- Fixing bugs
- Implementing improvements

**Protection:**

- No special protection
- Can be deleted after merge

---

### 4. `hotfix/*` - Critical Fix Branches

**Purpose:**

- Fix critical production issues
- Security patches
- Urgent bug fixes

**Naming Convention:**

- `hotfix/security-patch`
- `hotfix/critical-bug-fix`

**Workflow:**

- ✅ CI tests run on PR
- ✅ Build verification
- ✅ Can merge directly to `master` (with approval)
- ✅ Can merge to `release/*` for inclusion in next release

**When to use:**

- Critical security vulnerabilities
- Production-breaking bugs
- Urgent fixes needed immediately

**Protection:**

- Requires code review approval
- Requires all CI checks to pass
- Can merge to `master` or `release/*`

---

## Workflow Diagram

```
feature/new-feature
    │
    ├─→ PR ─→ release/1.0.1
    │              │
    │              ├─→ Testing & Validation
    │              │
    │              └─→ PR ─→ master
    │                           │
    │                           ├─→ Merge
    │                           │
    │                           └─→ Tag: v1.0.1
    │                                      │
    │                                      └─→ Triggers build-artifacts.yml
    │                                                 │
    │                                                 └─→ GitHub Release + Artifacts
    │
hotfix/critical-fix
    │
    ├─→ PR ─→ master (direct)
    │              │
    │              └─→ Tag: v1.0.2
    │                         │
    │                         └─→ Triggers build-artifacts.yml
```

---

## Detailed Workflow

### Feature Development Flow

**Step 1: Create Feature Branch**

```bash
git checkout master
git pull origin master
git checkout -b feature/my-new-feature
```

**Step 2: Develop and Test**

```bash
# Make changes
git add .
git commit -m "feat: Add new feature X"
git push origin feature/my-new-feature
```

**Step 3: Create PR to Release Branch**

```bash
# Create PR: feature/my-new-feature → release/1.0.1
# CI tests run automatically
# Code review
# Address review comments
```

**Step 4: Merge to Release Branch**

```bash
# After approval, merge PR
# CI tests run on release/1.0.1
# Optional: Preview artifacts created
```

**Step 5: Release Preparation**

```bash
# Test in release/1.0.1
# Update release notes
# Final validation
```

**Step 6: Create PR to Master**

```bash
# Create PR: release/1.0.1 → master
# CI tests run automatically
# Code review
# Merge to master
```

**Step 7: Create Version Tag**

```bash
git checkout master
git pull origin master
git tag -a v1.0.1 -m "Release 1.0.1"
git push origin v1.0.1
```

**Step 8: Automatic Release**

```bash
# Tag triggers build-artifacts.yml automatically
# All artifacts created
# GitHub Release created
# Optional: Publish to npm/PyPI/NuGet/Maven
```

---

### Hotfix Flow

**Step 1: Create Hotfix Branch from Master**

```bash
git checkout master
git pull origin master
git checkout -b hotfix/critical-fix
```

**Step 2: Fix and Test**

```bash
# Make fix
git add .
git commit -m "fix: Critical security patch"
git push origin hotfix/critical-fix
```

**Step 3: Create PR to Master**

```bash
# Create PR: hotfix/critical-fix → master
# CI tests run automatically
# Code review (expedited)
# Merge to master
```

**Step 4: Create Version Tag**

```bash
git checkout master
git pull origin master
git tag -a v1.0.2 -m "Hotfix: Critical security patch"
git push origin v1.0.2
```

**Step 5: Backport to Release Branch (Optional)**

```bash
# If fix should be in next release
git checkout release/1.0.1
git cherry-pick <commit-hash>
git push origin release/1.0.1
```

---

## Branch Protection Rules

### Master Branch

**Settings:**

- ✅ Require pull request reviews (1 approval minimum)
- ✅ Require status checks to pass (all CI jobs)
- ✅ Require branches to be up to date before merging
- ✅ Restrict who can push (only through PR)
- ✅ Allow force pushes: ❌ Disabled
- ✅ Allow deletions: ❌ Disabled

**Allowed PR Sources:**

- ✅ `release/*` branches
- ✅ `hotfix/*` branches
- ❌ `feature/*` branches (must go through release/*)

---

### Release Branches

**Settings:**

- ✅ Require pull request reviews (1 approval minimum)
- ✅ Require status checks to pass (all CI jobs)
- ✅ Require branches to be up to date before merging
- ✅ Restrict who can push (only through PR)

**Allowed PR Sources:**

- ✅ `feature/*` branches
- ✅ `hotfix/*` branches
- ✅ Other `release/*` branches (for backports)

---

## CI/CD Integration

### CI Workflow (`.github/workflows/ci.yml`)

**Triggers:**

```yaml
on:
  push:
    branches: [master, release/*]
  pull_request:
    branches: [master, release/*]
  workflow_dispatch:
```

**What it does:**

- Runs tests on all platforms (Linux, Windows, macOS)
- Tests all language bindings (Node.js, Python, C#, Java)
- Verifies builds
- Does NOT create artifacts
- Does NOT create releases

---

### Build Artifacts Workflow (`.github/workflows/build-artifacts.yml`)

**Triggers:**

```yaml
on:
  push:
    tags:
      - "v*.*.*"  # e.g., v1.0.1
  workflow_dispatch:
```

**What it does:**

- Creates all artifacts for all platforms
- Creates GitHub Release
- Uploads artifacts to GitHub Release
- Optional: Publishes to npm/PyPI/NuGet/Maven

---

## Versioning Strategy

### Version Format

- **Format**: `MAJOR.MINOR.PATCH` (Semantic Versioning)
- **Examples**: `1.0.1`, `1.1.0`, `2.0.0`

### Version Sources

**Current Approach (to be improved):**

- Hardcoded in `package.json`, `setup.py`, `pom.xml`, `.csproj`

**Recommended Approach:**

- Single source of truth (Git tag or VERSION file)
- Automatic version update during release

### Version Tagging

**Naming:**

- Format: `v{version}` (e.g., `v1.0.1`)
- Must match Semantic Versioning

**Creation:**

- Created manually after merge to master
- Or automatically via workflow (future enhancement)

---

## Release Process

### Standard Release

1. **Feature Development**
   - Create `feature/*` branches
   - Develop and test
   - Create PR to `release/*`

2. **Release Preparation**
   - Merge features to `release/*`
   - Test thoroughly
   - Update documentation
   - Prepare release notes

3. **Release to Master**
   - Create PR `release/*` → `master`
   - Review and merge
   - Create version tag `v*.*.*`

4. **Automatic Artifact Creation**
   - Tag triggers `build-artifacts.yml`
   - All artifacts created
   - GitHub Release created

5. **Optional: Package Publishing**
   - Publish to npm (Node.js)
   - Publish to PyPI (Python)
   - Publish to NuGet (C#)
   - Publish to Maven Central (Java)

---

### Hotfix Release

1. **Create Hotfix Branch**
   - From `master`
   - Fix the issue
   - Test thoroughly

2. **Merge to Master**
   - Create PR `hotfix/*` → `master`
   - Review and merge
   - Create version tag `v*.*.*`

3. **Automatic Artifact Creation**
   - Tag triggers `build-artifacts.yml`
   - All artifacts created
   - GitHub Release created

4. **Backport (Optional)**
   - Cherry-pick to `release/*` if needed

---

## Best Practices

### ✅ DO

1. **Always create PRs** - Never push directly to protected branches
2. **Keep branches up to date** - Rebase on target branch before PR
3. **Write clear commit messages** - Follow Conventional Commits
4. **Run tests locally** - Before creating PR
5. **Update documentation** - When adding features
6. **Create small PRs** - Easier to review and merge
7. **Delete merged branches** - Keep repository clean

### ❌ DON'T

1. **Don't push directly to master** - Always use PR
2. **Don't merge feature branches to master** - Go through release/*
3. **Don't create artifacts on PR** - Only on tags
4. **Don't skip CI checks** - All must pass
5. **Don't force push to protected branches** - Not allowed
6. **Don't delete protected branches** - Not allowed
7. **Don't hardcode versions** - Use single source of truth

---

## Branch Lifecycle

### Feature Branch Lifecycle

```
Created → Development → PR → Review → Merge → Deleted
```

**Typical Duration:**

- Development: 1-7 days
- Review: 1-3 days
- Total: 2-10 days

---

### Release Branch Lifecycle

```
Created → Feature Collection → Testing → PR to Master → Merged → (Optional: Keep for patches)
```

**Typical Duration:**

- Feature Collection: 1-4 weeks
- Testing: 3-7 days
- Total: 2-5 weeks

---

### Master Branch Lifecycle

```
Stable → Merge from Release → Tag → Artifacts → Stable (new version)
```

**Typical Duration:**

- Between releases: 2-8 weeks
- Release process: 1-2 days

---

## Migration from Current State

### Current State

- `master` - exists but CI configured for `main`/`develop`
- `release/1.0.1` - exists and working
- CI triggers: `main`, `develop` (not matching actual branches)

### Migration Steps

1. **Update CI Configuration**
   - Change `main` → `master` in `.github/workflows/ci.yml`
   - Add `release/*` to triggers
   - Remove `develop` if not used

2. **Configure Branch Protection**
   - Protect `master` branch
   - Protect `release/*` branches
   - Set up required checks

3. **Update Documentation**
   - Update CONTRIBUTING.md
   - Update README.md (if needed)
   - Create this document

4. **Test Workflow**
   - Create test feature branch
   - Create PR to release branch
   - Verify CI runs
   - Merge and verify

---

## Troubleshooting

### Issue: CI not running on master

**Problem:** CI configured for `main` but using `master`

**Solution:**

```yaml
# Update .github/workflows/ci.yml
on:
  push:
    branches: [master, release/*]  # Changed from [main, develop]
```

---

### Issue: Cannot push to master

**Problem:** Master is protected

**Solution:**

- Create PR from `release/*` or `hotfix/*`
- Get code review approval
- Ensure CI passes
- Merge via GitHub UI

---

### Issue: PR blocked by CI

**Problem:** CI checks failing

**Solution:**

- Check CI logs for errors
- Fix issues locally
- Push fixes to branch
- CI will re-run automatically

---

## References

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Last Updated**: 2025-11-15  
**Maintainer**: FastEmbed Team
