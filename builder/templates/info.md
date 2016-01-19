User Provided Configuration
===========================

```bash
# project name
PROJECT={{PROJECT}}

# base path for docker image name
IMGBASE={{IMGBASE}} 

# port that will be used for development web server
DEVPORT={{DEVPORT}}

# port that will be used for production web server
PRODPORT={{PRODPORT}}
```

Builder Configuration
=====================

```bash
UID     = {{UID}}
GID     = {{GID}}
ROOTDIR = {{ROOT}}
BUILDIR = {{BUILD_DIR}}
```

Volumes
=======

- `{{PROJECT}}-mod`: for persisting `node_modules` directory.