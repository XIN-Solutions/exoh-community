# Community edition — fresh install quickstart

Run the community Docker stack and complete first-run CMS setup. This repository is the public installer. The CMS source is not in this repo.

## Prerequisites

- Docker and Docker Compose (`docker-compose` 1.29 or the Compose V2 plugin)
- `openssl`

## 1. Install and start

From any directory:

```bash
curl -fsSL https://raw.githubusercontent.com/XIN-Solutions/exoh-community/master/community-up.sh | bash
```

Bash reads the script from the pipe, so the script file is not written to disk. The command creates `./exoh-community` (override with `EXOH_COMMUNITY_DIR`) and leaves only what the next start needs:

- `docker-compose.yml`
- `.env` with `PB_WWW_HOST=http://localhost:8090` and `CREATE_ACCOUNT_ENABLED=false`, written only when `.env` is missing
- `secrets/pb_admin_password.txt`, a random PocketBase superuser password (mode `644`) created only when that file is missing

The password is not printed. Compose 1.29 bind-mounts the secret as-is, and the app container runs as uid 1001, so mode `600` is unreadable. The password is not placed in `.env` or in the compose `environment` block.

The script then pulls the published images and starts the stack in the background. Re-running the pipe overwrites `docker-compose.yml` and leaves the secret, `.env`, and the PocketBase volume in place. Later commands in that directory are plain `docker-compose` commands. The file in this repository stays `docker-compose.community.yml` for a clone.

Pin a revision by replacing `master` in the URL with a tag or commit SHA.

### From a clone of this repo

```bash
./community-up.sh
```

That uses the `docker-compose.community.yml` in the clone instead of writing a new copy.

## 2. What the stack publishes

`pull` refreshes the published images. Compose does not build them. The app image is `dr.xinsolutions.co.nz/community/exoh-cms` and PocketBase is `dr.xinsolutions.co.nz/community/exoh-pocketbase`. Both default to `latest`. Pin a dated tag with `COMMUNITY_CMS_TAG` or `POCKETBASE_TAG` if you need one. Those `community/` paths are the public registry copies.

The compose file publishes **8080** (CMS), **3000** (frontend), and **8090** (PocketBase) on the host. The app container talks to PocketBase on the Docker network (`PB_HOST=http://pocketbase:8090`). The browser loads media and other `/api/files` URLs from `PB_WWW_HOST`.

Docker Compose 1.29 does not support `pull_policy`. The separate `pull` is what keeps `latest` current. If `docker-compose` is not on `PATH`, the script uses `docker compose`.

If the app container exits once because PocketBase is not accepting connections yet, `restart: unless-stopped` starts it again. There is no healthcheck on this stack.

Follow logs from the directory the pipe created:

```bash
docker-compose logs -f
```

From a clone of this repo:

```bash
docker-compose -f docker-compose.community.yml logs -f
```

## 3. Open the CMS and complete initial setup

1. Open [http://localhost:8080](http://localhost:8080).
2. `/` redirects to `/login`. When no loginable user exists yet, you see the **Initial setup** card instead of the normal sign-in form.
3. Fill in **organisation name**, **email**, **name**, and **password**, then submit.

A successful submit creates the first organisation and platform administrator, provisions the built-in service accounts, and signs you into the CMS (session cookie), same as a normal login.

The first organisation is created with MFA disabled (`requireMfa: false`) so you can sign in without enrolling MFA on day one.

## After setup

- Leave `CREATE_ACCOUNT_ENABLED` off if you do not want public self-signup. Add further people from the **organisations** console (invites), not via a public signup page.
- To reset the stack data, remove the `pb_data_community` volume and start again. Keep or replace `secrets/pb_admin_password.txt` as needed. PocketBase superuser password is aligned to that file on each PocketBase start when the secret is mounted.

Do not commit `secrets/pb_admin_password.txt` or `.env`.
