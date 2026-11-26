# dep-dlm-containers

Container images for the DEP DLM data orchestration layer: Rucio server and
daemons with the [Rucio OPA policy package](https://github.com/RI-SCALE/rucio-opa-policy-package),
and FTS with the patches DEP DLM needs. Used by
[dep-dlm-testbed](https://github.com/RI-SCALE/dep-dlm-testbed) and
[dep-dlm-deployment](https://github.com/RI-SCALE/dep-dlm-deployment), so both
run the same images.

Developed within RI-SCALE WP2 (DEP data lifecycle management).

## Images

| Image | Based on | Adds |
| --- | --- | --- |
| `rucio-server` | `rucio/rucio-server` | Policy package; gfal2 with http, xrootd and file plugins, for direct mode (conveyor and reaper inside the server) |
| `rucio-daemons` | `rucio/rucio-daemons` | Policy package (gfal2 is already upstream) |
| `fts` | FTS3, fts-rest-flask | OIDC and S3 (SigV4 header) patches, patched gfal2 and davix |

Published as `ghcr.io/ri-scale/dep-dlm-containers/<image>`. Test-only and
storage-side images (the `rucio-client` test runner, Teapot, Keycloak) stay
in the testbed for now. Rucio source patches are not baked in; the
deployments mount them at runtime.

## Building

```bash
docker build -f rucio/Dockerfile --build-arg RUCIO_COMPONENT=server  -t rucio-server  .
docker build -f rucio/Dockerfile --build-arg RUCIO_COMPONENT=daemons -t rucio-daemons .
docker build -f fts/Dockerfile -t fts .
```

Versions (Rucio release, policy package and its SHA-256) are build args with
pinned defaults in the Dockerfiles. Pull requests build every image without
pushing.

## Releasing

Every merge to `main` publishes all images (`images.yml`), each with a build
provenance attestation and two tags:

| Tag | Example | Use |
| --- | --- | --- |
| Full commit SHA | `rucio-server:<sha>` | What consumers pin; never moves |
| Upstream version + short SHA | `rucio-server:41.2.1-dep.<short-sha>` | Readable; can't be mistaken for an upstream release |

There is no `latest` and no plain upstream version tag. The upstream base is
also recorded in the OCI labels (`org.opencontainers.image.base.name`).

Verify (needs gh auth login or GH_TOKEN):

```bash
gh attestation verify oci://ghcr.io/ri-scale/dep-dlm-containers/rucio-server:<sha> --repo RI-SCALE/dep-dlm-containers
```

## Using a new image

1. Merge the change here; note the commit SHA.
2. Bump the tag in dep-dlm-testbed and run its end-to-end suite.
3. Promote to dep-dlm-deployment with the validated testbed commit.

FTS patches change upstream code: each references its upstream issue or
pull request and is dropped once that is released.
