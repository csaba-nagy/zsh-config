# ZSH Configuration Fixes & Improvements

## Problem Statement
Node.js was not accessible in new shell sessions until the `upgrade` function was run manually.

## Root Cause Analysis

### Primary Issue: FNM (Node Version Manager) Initialization
- **Problem**: FNM was initialized but didn't ensure a default Node version was installed
- **Why it occurred**: 
  - FNM's `fnm env --use-on-cd` creates a "multishell" environment with temporary directories
  - This mechanism fails in subshells (e.g., `zsh -c '...'`) where the temporary directory doesn't exist
  - No fallback when multishell mode failed
- **Impact**: `node` command was unavailable until `upgrade` installed and configured it

## Fixes Implemented

### 1. **Node Availability (MAIN FIX)** ✅
**File**: `modules/tools.zsh` (lines 41-62)

**Changes**:
- Auto-detect and auto-install Node LTS if FNM has no default version
- Added fallback PATH entry: if `node` is still unavailable after FNM init, manually add FNM's default version bin directory to PATH
- This ensures Node is available immediately on first shell startup

**Impact**: 
```bash
# Before: node not found until 'upgrade' was run
# After: node v24.15.0 immediately available
$ node --version
v24.15.0
```

---

### 2. **Tool Binary Path Fallbacks** ✅
**File**: `modules/tools.zsh` (lines 45, 58)

**Before**:
```zsh
_ztool_init fnm "$HOME/.cargo/bin/fnm" "fnm env --use-on-cd --shell zsh"
_ztool_init direnv "$HOME/.local/bin/direnv" "direnv hook zsh"
```

**After**:
```zsh
_fnm_bin="$(command -v fnm 2>/dev/null || echo "$HOME/.cargo/bin/fnm")"
_ztool_init fnm "$_fnm_bin" "fnm env --use-on-cd --shell zsh"

_direnv_bin="$(command -v direnv 2>/dev/null || echo "$HOME/.local/bin/direnv")"
_ztool_init direnv "$_direnv_bin" "direnv hook zsh"
```

**Impact**: Tools are now looked up in PATH first, with hardcoded paths as fallback. More portable across machines.

---

### 3. **WSL Clipboard Alias Robustness** ✅
**File**: `modules/aliases.zsh` (line 91)

**Before**:
```zsh
alias pbpaste='powershell.exe Get-Clipboard | tr -d "\r"'
```

**After**:
```zsh
alias pbpaste='powershell.exe Get-Clipboard | sed "s/\r$//"'
```

**Why**: `tr -d "\r"` can be unreliable with different line endings; `sed` is more robust.

---

### 4. **Error Handling Improvements** ✅
**File**: `modules/functions.zsh` (lines 86-102, 68-79)

**interactive_kill() function**:
- Added explicit error handling for FZF cancellation
- Better error messages when no processes are selected
- Proper exit codes for better script composition

**bootstrap() function**:
- Added git availability check before attempting to use it
- Prevents cryptic errors if git is not in PATH

---

### 5. **Code Cleanliness** ✅
**File**: `modules/aliases.zsh` (lines 34-45, 48-49, 113-114)

**Changes**:
- Removed commented-out docker aliases (redundant with plugin aliases)
- Removed commented-out Go aliases (provided by OMZP::golang)
- Added clear comments explaining which plugin provides base aliases
- Reduced visual clutter without losing functionality

---

## Testing Results

```bash
# Test 1: Node available immediately
$ zsh -c 'node --version'
v24.15.0  ✅

# Test 2: NPM works
$ npm --version
11.14.1  ✅

# Test 3: Global npm packages available
$ npm list -g --depth=0 | head -5
@antfu/ni@30.1.0
@wordpress/env@11.5.0
corepack@0.34.6
eslint@10.4.0
npkill@0.12.2  ✅
```

---

## Files Modified

| File | Changes | Lines |
|------|---------|-------|
| `modules/tools.zsh` | FNM init fix, tool fallbacks, PATH handling | +28, -2 |
| `modules/aliases.zsh` | Cleaned comments, WSL alias fix | +3, -23 |
| `modules/functions.zsh` | Error handling, git check | +3, -7 |

---

## What Didn't Change (and Why)

- **Tool initialization order**: Already optimal (direnv before zoxide)
- **FZF configuration**: Already well-configured
- **Keybindings**: No issues identified
- **Completion configuration**: No issues identified
- **Zinit plugin loading**: No issues identified

---

## Migration Notes

If you have existing shell sessions:
1. Start a new shell session to get the fixes
2. Or run: `exec zsh` to reload the configuration
3. No manual upgrades needed going forward

---

## Future Improvements (Optional)

If you want to add:
- [ ] Auto-update Node LTS weekly
- [ ] Cache FNM's version list to speed up initialization
- [ ] Add health check function `zsh-health` to diagnose config issues
- [ ] Add profiling output option for startup time optimization

---

**Status**: All critical issues resolved ✅  
**Commit**: `fe6e703ff3c0`
