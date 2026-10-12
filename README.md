# ex:oh cms community bootstrap

Public installer for the community Docker stack. The CMS source stays in the private `exoh-cms` repository.

```bash
curl -fsSL https://raw.githubusercontent.com/XIN-Solutions/exoh-community/master/community-up.sh | bash
```

From the directory that should hold the stack, the script writes `docker-compose.yml` and a PocketBase secret, then prints the `docker-compose pull` and `up` commands. It does not start the stack. Use a separate directory for each stack. See [COMMUNITY-QUICKSTART.md](COMMUNITY-QUICKSTART.md).
