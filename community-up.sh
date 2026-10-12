#!/usr/bin/env bash
set -euo pipefail

write_compose() {
  cat >"$1" <<'EOF'
services:
  pocketbase:
    image: dr.xinsolutions.co.nz/community/exoh-pocketbase:${POCKETBASE_TAG:-latest}
    ports:
      - "${PB_PORT:-8090}:8090"
    volumes:
      - pb_data_community:/pb_data
    networks:
      - exoh-community-network
    restart: unless-stopped
    environment:
      - PB_ADMIN_EMAIL=pb-superuser@localhost.local
    secrets:
      - pb_admin_password

  app:
    image: dr.xinsolutions.co.nz/community/exoh-cms:${COMMUNITY_CMS_TAG:-latest}
    ports:
      - "${CMS_PORT:-8080}:8080"
      - "${FE_PORT:-3000}:3000"
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
      - PB_ADMIN_EMAIL=pb-superuser@localhost.local
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

CMS_PORT="${CMS_PORT:-8080}"
FE_PORT="${FE_PORT:-3000}"
PB_PORT="${PB_PORT:-8090}"

if [[ -f "$0" ]]; then
  ROOT="$(cd "$(dirname "$0")" && pwd)"
  COMPOSE_FILE="${ROOT}/docker-compose.community.yml"
else
  ROOT="${PWD}"
  COMPOSE_FILE="${ROOT}/docker-compose.yml"
  write_compose "${COMPOSE_FILE}"
fi

mkdir -p "${ROOT}/secrets"
SECRET_FILE="${ROOT}/secrets/pb_admin_password.txt"
if [[ ! -f "${SECRET_FILE}" ]]; then
  openssl rand -base64 24 >"${SECRET_FILE}"
fi
chmod 644 "${SECRET_FILE}"

if [[ ! -f "${ROOT}/.env" ]]; then
  cat >"${ROOT}/.env" <<EOF
PB_WWW_HOST=http://localhost:${PB_PORT}
CREATE_ACCOUNT_ENABLED=false
CMS_PORT=${CMS_PORT}
FE_PORT=${FE_PORT}
PB_PORT=${PB_PORT}
EOF
fi

if command -v docker-compose >/dev/null 2>&1; then
  compose_bin="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  compose_bin="docker compose"
else
  compose_bin="docker-compose"
fi

compose_file="$(basename "${COMPOSE_FILE}")"
printf 'Stack directory: %s\n' "${ROOT}"
printf 'CMS: http://localhost:%s\n' "${CMS_PORT}"
printf '\nStart the stack from this directory:\n'
if [[ "${compose_file}" == "docker-compose.yml" ]]; then
  printf '  %s pull\n' "${compose_bin}"
  printf '  %s up\n' "${compose_bin}"
else
  printf '  %s -f %s pull\n' "${compose_bin}" "${compose_file}"
  printf '  %s -f %s up\n' "${compose_bin}" "${compose_file}"
fi
