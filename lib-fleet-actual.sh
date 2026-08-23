#!/usr/bin/env bash
# Worktree helpers so Desktop can stack from /Users/pacman/GITHUB_ACTUAL
# without `git checkout -B` on those dirty trees (ERM #425 was built there).
# Sourced by stack-fleet-open-prs.sh. Safe to source in tests.

fleet_resolved_path() {
  (cd "$1" && pwd -P) 2>/dev/null
}

fleet_detect_actual() {
  if [[ -n "${FLEET_ACTUAL:-}" ]]; then
    return 0
  fi
  local candidate
  for candidate in /Users/pacman/GITHUB_ACTUAL "${HOME:-}/GITHUB_ACTUAL"; do
    if [[ -e "${candidate}/ERMT/.git" || -e "${candidate}/ERM/.git" ]]; then
      FLEET_ACTUAL="${candidate}"
      echo "Detected local fleet ${FLEET_ACTUAL} — will worktree, not checkout in-place"
      return 0
    fi
  done
}

# True when DEST is the GITHUB_ACTUAL tree itself (would trash dirty work).
fleet_dest_is_actual_inplace() {
  local dest="$1"
  local actual="$2"
  local repo="${3:-}"
  [[ -n "${actual}" ]] || return 1
  local dest_root actual_root
  dest_root="$(fleet_resolved_path "${dest}")" || dest_root="${dest}"
  actual_root="$(fleet_resolved_path "${actual}")" || actual_root="${actual}"
  if [[ "${dest_root}" == "${actual_root}" ]]; then
    return 0
  fi
  if [[ -n "${repo}" ]]; then
    local dest_repo actual_repo
    dest_repo="$(fleet_resolved_path "${dest}/${repo}")" || return 1
    actual_repo="$(fleet_resolved_path "${actual}/${repo}")" || return 1
    [[ "${dest_repo}" == "${actual_repo}" ]] && return 0
  fi
  return 1
}

# Populate dest/repo from FLEET_ACTUAL via worktree, or clone with gh.
# Does not checkout -B on GITHUB_ACTUAL. Returns 1 on inplace refuse.
fleet_prepare_repo() {
  local org="$1"
  local repo="$2"
  local dest="$3"
  local branch="$4"
  local root="${dest}/${repo}"
  local src=""
  if [[ -n "${FLEET_ACTUAL:-}" ]]; then
    src="${FLEET_ACTUAL%/}/${repo}"
  fi

  if fleet_dest_is_actual_inplace "${dest}" "${FLEET_ACTUAL:-}" "${repo}"; then
    echo "REFUSE in-place on GITHUB_ACTUAL/${repo} (ERM #425 dirty checkout). Use FLEET_SRC=/tmp/fleet-src so this script worktrees." >&2
    return 1
  fi

  # Worktrees have a .git *file*, not a directory.
  if [[ -e "${root}/.git" ]]; then
    git -C "${root}" fetch origin --prune
    return 0
  fi

  if [[ -n "${src}" && -e "${src}/.git" ]]; then
    echo "WORKTREE ${src} -> ${root}"
    git -C "${src}" fetch origin --prune || true
    mkdir -p "$(dirname "${root}")"
    local default
    default="$(git -C "${src}" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
    default="${default:-main}"
    if git -C "${src}" show-ref --verify --quiet "refs/remotes/origin/${default}"; then
      git -C "${src}" worktree add -B "${branch}" "${root}" "origin/${default}"
    else
      git -C "${src}" worktree add -B "${branch}" "${root}"
    fi
    return $?
  fi

  if [[ "${FLEET_PREPARE_NO_CLONE:-0}" == "1" ]]; then
    echo "NO_CLONE ${org}/${repo}" >&2
    return 2
  fi
  gh repo clone "${org}/${repo}" "${root}"
}
