#!/usr/bin/env bash
set -euo pipefail

write_compose() {
  cat >"$1" <<'EOF'
services:
  pocketbase:
    image: dr.xinsolutions.co.nz/community/exoh-pocketbase:${POCKETBASE_TAG:-latest}
    container_name: exoh-pocketbase-community
    ports:
      - "8090:8090"
    volumes:
      - pb_data_community:/pb_data
    networks:
      - exoh-community-network
    restart: unless-stopped
    environment:
      - PB_ADMIN_EMAIL=pb-superuser@localhost
    secrets:
      - pb_admin_password

  app:
    image: dr.xinsolutions.co.nz/community/exoh-cms:${COMMUNITY_CMS_TAG:-latest}
    container_name: exoh-app-community
    ports:
      - "8080:8080"
      - "3000:3000"
    volumes:
      - ./.env:/app/.env:ro
    depends_on:
      - pocketbase
    networks:
      - exoh-community-network
    restart: unless-stopped
    environment:
      - PB_HOST=http://pocketbase:8090
      - COMMUNITY_EDITION=true
      - PB_ADMIN_EMAIL=pb-superuser@localhost
    secrets:
      - pb_admin_password

volumes:
  pb_data_community:
    driver: local

networks:
  exoh-community-network:
    driver: bridge

secrets:
  pb_admin_password:
    file: ./secrets/pb_admin_password.txt
EOF
}

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to create the PocketBase secret." >&2
  exit 1
fi

script_path="${BASH_SOURCE[0]:-}"
if [[ -n "${script_path}" && -f "${script_path}" ]]; then
  ROOT="$(cd "$(dirname "${script_path}")" && pwd)"
  COMPOSE_FILE="${ROOT}/docker-compose.community.yml"
else
  ROOT="${EXOH_COMMUNITY_DIR:-${PWD}/exoh-community}"
  mkdir -p "${ROOT}"
  COMPOSE_FILE="${ROOT}/docker-compose.community.yml"
  write_compose "${COMPOSE_FILE}"
fi

mkdir -p "${ROOT}/secrets"
SECRET_FILE="${ROOT}/secrets/pb_admin_password.txt"
if [[ ! -f "${SECRET_FILE}" ]]; then
  openssl rand -base64 24 >"${SECRET_FILE}"
fi
chmod 644 "${SECRET_FILE}"

if [[ ! -f "${ROOT}/.env" ]]; then
  cat >"${ROOT}/.env" <<'EOF'
PB_WWW_HOST=http://localhost:8090
CREATE_ACCOUNT_ENABLED=false
EOF
fi

if command -v docker-compose >/dev/null 2>&1; then
  compose() { docker-compose "$@"; }
elif docker compose version >/dev/null 2>&1; then
  compose() { docker compose "$@"; }
else
  echo "Docker Compose is not installed." >&2
  exit 1
fi

compose -f "${COMPOSE_FILE}" pull
compose -f "${COMPOSE_FILE}" up -d

printf 'Stack directory: %s\n' "${ROOT}"
printf 'CMS: http://localhost:8080\n'
printf 'Logs: (cd %q && docker-compose -f docker-compose.community.yml logs -f)\n' "${ROOT}"
