#!/usr/bin/env bash
# Create the 'lfs' user and group used by the build scripts
# Safe: uses sudo when not run as root, checks for existing user/group

set -euo pipefail

USERNAME=lfs
GROUP=lfs
USER_UID=
HOME_DIR="/home/${USERNAME}"
SHELL_BIN="/bin/bash"
ADD_SUDO=false
SET_PASSWORD=false

usage(){
  cat <<EOF
Usage: sudo bash script/create-lfs-user.sh [options]

Options:
  --uid UID        Set numeric UID for the new user
  --home DIR       Home directory (default: /home/lfs)
  --shell SHELL    Login shell (default: /bin/bash)
  --sudo           Add ${USERNAME} to sudoers (NOPASSWD)
  --passwd         Prompt to set password for ${USERNAME}
  -h, --help       Show this help

This script will create group '${GROUP}' (if missing) and user '${USERNAME}'.
If you are not root it will attempt to use sudo for privileged actions.
EOF
}

while [[ ${1:-} != "" ]]; do
  case "$1" in
    --uid) shift; USER_UID=${1:-}; shift ;;
    --home) shift; HOME_DIR=${1:-}; shift ;;
    --shell) shift; SHELL_BIN=${1:-}; shift ;;
    --sudo) ADD_SUDO=true; shift ;;
    --passwd) SET_PASSWORD=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Use sudo when not root
if [ "$(id -u)" -ne 0 ]; then
  SUDO_CMD="sudo"
else
  SUDO_CMD=""
fi

info(){ echo "[INFO] $*"; }
err(){ echo "[ERROR] $*" >&2; }

info "Preparing to create user '${USERNAME}' (group: '${GROUP}')"

# Create group if missing
if getent group "$GROUP" >/dev/null; then
  info "Group '$GROUP' already exists"
else
  info "Creating group '$GROUP'"
  $SUDO_CMD groupadd "$GROUP"
fi

# Create user if missing
if id -u "$USERNAME" >/dev/null 2>&1; then
  info "User '$USERNAME' already exists (uid: $(id -u $USERNAME))";
  exit 0
fi

USERADD_CMD=(useradd -m -d "$HOME_DIR" -s "$SHELL_BIN" -g "$GROUP")
if [ -n "$USER_UID" ]; then
  USERADD_CMD+=( -u "$USER_UID" )
fi
USERADD_CMD+=( "$USERNAME" )

info "Running: ${USERADD_CMD[*]}"
$SUDO_CMD "${USERADD_CMD[@]}"

# Ensure home exists and ownership correct
$SUDO_CMD mkdir -p "$HOME_DIR"
$SUDO_CMD chown -R "$USERNAME:$GROUP" "$HOME_DIR"

if $ADD_SUDO; then
  info "Adding $USERNAME to sudoers (NOPASSWD)"
  # Create sudoers file for lfs
  echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | $SUDO_CMD tee /etc/sudoers.d/99_lfs >/dev/null
  $SUDO_CMD chmod 0440 /etc/sudoers.d/99_lfs
fi

if $SET_PASSWORD; then
  info "Setting password for $USERNAME"
  if [ "$(id -u)" -eq 0 ]; then
    passwd "$USERNAME"
  else
    echo "You need to run this script as root (or with sudo) to set a password interactively."
    echo "Run: sudo passwd $USERNAME"
  fi
fi

info "User '$USERNAME' created. Home: $HOME_DIR, Shell: $SHELL_BIN"

exit 0
