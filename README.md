# dep-dlm-containers

Container images for the DEP DLM data orchestration layer: Rucio server and
daemons with the [Rucio OPA policy package](https://github.com/RI-SCALE/rucio-opa-policy-package),
and FTS with the changes DEP DLM needs. Used by
[dep-dlm-testbed](https://github.com/RI-SCALE/dep-dlm-testbed) and
[dep-dlm-deployment](https://github.com/RI-SCALE/dep-dlm-deployment), so both
run the same images.

Developed within RI-SCALE WP2 (DEP data lifecycle management).

## Images

| Image | Based on | Adds |
| --- | --- | --- |
| `rucio-server` | `rucio/rucio-server` | Policy package; gfal2 with http, xrootd and file plugins, for direct mode (conveyor and reaper inside the server) |
| `rucio-daemons` | `rucio/rucio-daemons` | Policy package (gfal2 is already upstream) |
| `fts` | FTS3, fts-rest-flask | FTS3 and gfal2 from forks (token and S3 SigV4 header fixes), davix with SigV4 header signing |

Published as `ghcr.io/ri-scale/dep-dlm-containers/<image>`. Test-only and
storage-side images (the `rucio-client` test runner, Teapot, Keycloak) stay
in the testbed for now. Rucio and fts-rest-flask source patches are not
baked in; the deployments mount them at runtime.

## Building

Needs Docker, Make and pre-commit; the devcontainer has all three.

```bash
make hooks                      # once: git pre-commit hook
make check                      # hadolint, shellcheck, YAML (pre-commit)
make build scan IMAGE=fts       # build locally and scan with Trivy
make help                       # all targets
```

Or with plain Docker:

```bash
docker build rucio --build-arg RUCIO_COMPONENT=server  -t rucio-server
docker build rucio --build-arg RUCIO_COMPONENT=daemons -t rucio-daemons
docker build fts -t fts
```

Versions (Rucio release, policy package and its SHA-256, FTS sources) are
build args with pinned defaults in the Dockerfiles.

## Releasing

Pull requests and `main` lint and build every image without pushing; pull
requests also scan each for secrets (fail) and fixable HIGH/CRITICAL
vulnerabilities (reported). A `vX.Y.Z` tag builds, scans and publishes all
images (`release.yml` → `images.yml`), each with build provenance and SPDX
SBOM attestations, and creates the GitHub Release:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
```

| Tag | Example | Use |
| --- | --- | --- |
| Full commit SHA | `rucio-server:<sha>` | What consumers pin; never moves |
| Release | `rucio-server:41.2.1-dep.0.1.0` | Readable; can't be mistaken for an upstream release |

There is no `latest` and no plain upstream version tag. The OCI labels record
the source repository and commit.

Verify (needs gh auth login or GH_TOKEN):

```bash
# build provenance
gh attestation verify oci://ghcr.io/ri-scale/dep-dlm-containers/fts:<sha> --repo RI-SCALE/dep-dlm-containers
# SBOM
gh attestation verify oci://ghcr.io/ri-scale/dep-dlm-containers/fts:<sha> --repo RI-SCALE/dep-dlm-containers \
  --predicate-type https://spdx.dev/Document/v2.3
```

## Using a new image

1. Release here (`vX.Y.Z`); note the commit SHA.
2. Bump the tag in dep-dlm-testbed and run its end-to-end suite.
3. Promote to dep-dlm-deployment with the validated testbed commit.

A release that fails in the testbed is replaced by the next patch version.
Forked components are temporary: each change references its upstream pull
request (e.g. cern-fts/gfal2#28) and moves back to upstream once released.
