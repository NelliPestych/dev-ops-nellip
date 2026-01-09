#!/usr/bin/env bash
set -euo pipefail

# ========= Helpers =========
log() { echo -e "\n[INFO] $*"; }
warn() { echo -e "\n[WARN] $*" >&2; }
err() { echo -e "\n[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Please run as root: sudo $0"
    exit 1
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

version_ge() {
  dpkg --compare-versions "$1" ge "$2"
}

ensure_apt_updated=false
apt_update_once() {
  if [[ "${ensure_apt_updated}" == "false" ]]; then
    log "Updating apt package index..."
    apt-get update -y
    ensure_apt_updated=true
  fi
}

# ========= Docker =========
install_docker() {
  if command_exists docker; then
    log "Docker already installed: $(docker --version || true)"
    return 0
  fi

  log "Installing Docker..."
  apt_update_once
  apt-get install -y ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
  > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# ========= Docker Compose =========
install_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose already installed"
    return 0
  fi

  log "Installing Docker Compose plugin..."
  apt_update_once
  apt-get install -y docker-compose-plugin
}

# ========= Python =========
install_python() {
  if command_exists python3; then
    log "Python already installed: $(python3 --version)"
    return 0
  fi

  log "Installing Python and pip..."
  apt_update_once
  apt-get install -y python3 python3-pip python3-venv
}

# ========= Django =========
install_django() {
  if command_exists django-admin; then
    log "Django already installed: $(django-admin --version)"
    return 0
  fi

  log "Installing Django..."
  python3 -m pip install --upgrade pip
  python3 -m pip install django
}

# ========= MAIN =========
main() {
  require_root

  install_docker
  install_docker_compose
  install_python
  install_django

  log "✅ All tools installed successfully"
}

main "$@"

