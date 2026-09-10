# Wiz reusable workflows

Centralized GitHub Actions reusable workflows for Wiz CLI directory/code and
container-image scans.

## Workflows

| Workflow | Target | Selectable scan types |
| --- | --- | --- |
| `wiz-dir-scan.yml` | A checked-out repository or directory | `vulnerabilities`, `sast`, `iac`, `secrets`, `sensitive-data`, `malware`, `software-supply-chain`, `ai-models`, or `all` |
| `wiz-image-scan.yml` | A container image built by the workflow, pulled from a registry, or supplied as an image archive | `vulnerabilities`, `secrets`, `sensitive-data`, `software-supply-chain`, `malware`, or `all` |

Both workflows:

- authenticate with `WIZ_CLIENT_ID` and `WIZ_CLIENT_SECRET`;
- save human-readable, JSON, SARIF, and console-log reports;
- upload reports to the calling GitHub Actions run, even when the scan fails;
- publish results to Wiz by default (set `publish: false` to keep results out of
  **Findings > Code & Build Scans**);
- preserve Wiz CLI exit codes, including policy failure exit code `4`;
- expose the artifact name, artifact URL, and Wiz CLI exit code as reusable
  workflow outputs.

Wiz CLI directory scans run all applicable analyzers by default. For individual
or comma-separated selections, the workflow uses Wiz CLI's
`--disabled-scanners` option to disable every unselected analyzer, and selects
the corresponding built-in CI/CD policies. Use a custom `policies` value when
your tenant uses custom policy names or when selecting `ai-models`, which has no
default built-in CI/CD policy in the currently queried tenant.

## Prerequisites

1. Create a Wiz CLI CI/CD service account with the minimum project scope needed
   by the callers.
2. Store its credentials as Actions secrets named `WIZ_CLIENT_ID` and
   `WIZ_CLIENT_SECRET` in each caller repository, or as organization secrets
   restricted to approved repositories.
3. If this repository is private, allow approved caller repositories under
   **Settings > Actions > General > Access**.
4. Create a release tag for this repository. For production callers, replace
   `v1` in the examples with a reviewed full commit SHA for immutable reuse.

## Directory/code scan

```yaml
name: Wiz directory scan

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  wiz-directory:
    uses: arun-wiz/wiz-workflows/.github/workflows/wiz-dir-scan.yml@v1
    with:
      scan_types: all
      path: .
      publish: true
      artifact_retention_days: 14
    secrets:
      WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
      WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}
```

Select individual or multiple scan types with a comma-separated value:

```yaml
    with:
      scan_types: sast,secrets
```

To apply tenant-specific policies, pass their exact, case-sensitive names:

```yaml
    with:
      scan_types: sast,secrets
      policies: My SAST blocking policy,My secrets blocking policy
```

## Container-image scan

The default behavior builds the image in the reusable workflow's runner before
scanning it. This avoids assuming that a Docker image built in another job is
available on a fresh runner.

```yaml
name: Wiz image scan

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  wiz-image:
    uses: arun-wiz/wiz-workflows/.github/workflows/wiz-image-scan.yml@v1
    with:
      image: local/wiz-scan:${{ github.sha }}
      build_image: true
      build_context: .
      dockerfile: Dockerfile
      scan_types: all
      artifact_retention_days: 14
    secrets:
      WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
      WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}
```

To scan an existing registry image, disable the build and enable pulling:

```yaml
    with:
      image: ghcr.io/example/application:1.2.3
      build_image: false
      pull_image: true
      scan_types: vulnerabilities,secrets
```

For a private registry, also pass `registry`, `registry_username`, and the
optional `REGISTRY_PASSWORD` secret. Do not use `secrets: inherit`; pass only
the credentials required by the workflow.

## Running both target types

Call both reusable workflows as separate jobs. They can run in parallel and
produce independently named artifacts in the same caller run:

```yaml
jobs:
  directory:
    uses: arun-wiz/wiz-workflows/.github/workflows/wiz-dir-scan.yml@v1
    with:
      scan_types: all
    secrets:
      WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
      WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}

  image:
    uses: arun-wiz/wiz-workflows/.github/workflows/wiz-image-scan.yml@v1
    with:
      image: local/wiz-scan:${{ github.sha }}
      scan_types: all
    secrets:
      WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
      WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}
```

## Important behavior

- `fail_on_policy: true` (default) makes Wiz policy failures fail the job.
  Setting it to `false` suppresses only exit code `4`; authentication, command,
  network, and other operational errors still fail the job.
- `policy_hits: DISABLED` (default) includes all detected findings in reports.
  Use `BLOCK` or `AUDIT` to narrow report visibility. This setting does not
  change the scan's exit code.
- `publish: false` adds Wiz CLI's `--no-publish`; report artifacts are still
  uploaded to GitHub.
- The Wiz CLI binary comes from Wiz's documented HTTPS `latest` endpoint and
  its version is captured in every artifact. GitHub actions are pinned to full
  commit SHAs and tracked by Dependabot.

## Documentation used

- [Integrate Wiz CLI with GitHub](https://docs.wiz.io/docs/github-pipeline)
- [Scan directories with Wiz CLI](https://docs.wiz.io/docs/scan-directories-with-wiz-cli)
- [Scan and tag container images with Wiz CLI](https://docs.wiz.io/docs/scan-and-tag-container-images-with-wiz-cli)
- [How Wiz CLI works](https://docs.wiz.io/docs/how-wiz-cli-works)
- [GitHub reusable workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)
- [GitHub Actions security hardening](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats)
