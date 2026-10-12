# ex:oh cms community bootstrap

Public installer for the community Docker stack. The CMS source stays in the private `exoh-cms` repository.

```bash
curl -fsSL https://raw.githubusercontent.com/XIN-Solutions/exoh-community/master/community-up.sh | bash
```

The script creates `./exoh-community`, writes the compose file and a PocketBase secret, pulls the published images, and starts the stack. See [COMMUNITY-QUICKSTART.md](COMMUNITY-QUICKSTART.md).
