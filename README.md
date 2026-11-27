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

```bash
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

Pull requests lint, build every image without pushing and scan each for
fixable HIGH/CRITICAL vulnerabilities and secrets.

## Releasing

Every merge to `main` publishes all images (`images.yml`), each with build
provenance and SPDX SBOM attestations and two tags:

| Tag | Example | Use |
| --- | --- | --- |
| Full commit SHA | `rucio-server:<sha>` | What consumers pin; never moves |
| Upstream version + short SHA | `rucio-server:41.2.1-dep.<short-sha>` | Readable; can't be mistaken for an upstream release |

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

1. Merge the change here; note the commit SHA.
2. Bump the tag in dep-dlm-testbed and run its end-to-end suite.
3. Promote to dep-dlm-deployment with the validated testbed commit.

Forked components are temporary: each change references its upstream pull
request (e.g. cern-fts/gfal2#28) and moves back to upstream once released.
