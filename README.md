# Debian 13 (trixie) STIG-Ready Baseline InSpec Profile

This InSpec profile can help programs automate security compliance checks of `Debian 13 (trixie)` systems against Department of Defense (DoD) STIG-style guidance.

- Profile Version: `0.1.0`
- Derived from: [Canonical Ubuntu 24.04 LTS STIG baseline](https://github.com/mitre/canonical-ubuntu-24.04-lts-stig-baseline) (Canonical Ubuntu 24.04 LTS STIG, Version 1 Release 4, Benchmark Date 22 Jan 2026)

This profile uses the [InSpec](https://github.com/inspec/inspec) open-source compliance validation language to support automation of the required compliance, security and policy testing for Assessment and Authorization (A&A) and Authority to Operate (ATO) decisions and Continuous Authority to Operate (cATO) processes.

Table of Contents
=================

- [Why This Profile Is an Overlay](#why-this-profile-is-an-overlay)
- [Benchmark Information](#benchmark-information)
- [Getting Started](#getting-started)
  - [InSpec (CINC-auditor) setup](#inspec-cinc-auditor-setup)
  - [Intended Usage](#intended-usage)
  - [Container-Aware Testing](#container-aware-testing)
  - [Tailoring to Your Environment](#tailoring-to-your-environment)
  - [Testing the Profile Controls](#testing-the-profile-controls)
- [Running the Profile](#running-the-profile)
  - [Directly from Github](#directly-from-github)
  - [Using a local Archive copy](#using-a-local-archive-copy)
  - [Different Run Options](#different-run-options)
- [Using Heimdall for Viewing Test Results](#using-heimdall-for-viewing-test-results)
- [FIPS 140 on Debian](#fips-140-on-debian)
- [Authors](#authors)
- [NOTICE](#notice)

## Why This Profile Is an Overlay

DISA publishes no STIG for Debian. Debian is, however, the upstream distribution from which Ubuntu is built, and Canonical publishes DISA STIGs for Ubuntu LTS releases — so the Ubuntu STIG is the closest published guidance that exists for a Debian system.

This profile is therefore an InSpec overlay of the [Canonical Ubuntu 24.04 LTS STIG baseline](https://github.com/mitre/canonical-ubuntu-24.04-lts-stig-baseline) maintained by the MITRE SAF team. It runs the full upstream control set against Debian 13 and overrides, in `controls/overlay.rb`, only the checks where Debian genuinely differs from Ubuntu — different packaging conventions, different file locations, or requirements with no Debian equivalent. Ubuntu 24.04 was chosen for Debian 13 because it is the newest STIG-covered release and the closest match to trixie's component set (kernel 6.x, systemd 25x, modern PAM); Debian 13 is somewhat newer than Ubuntu 24.04 in places (e.g. OpenSSL 3.5 vs 3.0), which individual overlay controls account for.

[top](#table-of-contents)

## Benchmark Information

The DISA RME and DISA SD Office, along with their vendor partners, create and maintain a set of Security Technical Implementation Guides for applications, computer systems and networks connected to the Department of Defense (DoD). These guidelines are the primary security standards used by the DoD agencies.

Requirements associated with the Canonical Ubuntu 24.04 LTS STIG — and, through this overlay, with this profile — are derived from the [Security Requirements Guides](https://csrc.nist.gov/glossary/term/security_requirements_guide) and align to the [National Institute of Standards and Technology](https://www.nist.gov/) (NIST) [Special Publication (SP) 800-53](https://csrc.nist.gov/Projects/risk-management/sp800-53-controls/release-search#!/800-53) Security Controls, [DoD Control Correlation Identifier](https://public.cyber.mil/stigs/cci/) and related standards. Each control in this profile inherits the upstream control's compliance metadata (STIG IDs, SRG IDs, CCIs, NIST tags), so downstream tooling sees the same mappings it would from the Ubuntu profile.

[top](#table-of-contents)

## Getting Started

### InSpec (CINC-auditor) setup

For maximum flexibility/accessibility, `cinc-auditor`, the open-source packaged binary version of Chef InSpec, should be used, compiled by the CINC (CINC Is Not Chef) project in coordination with Chef using Chef's always-open-source InSpec source code. For more information see [CINC Home](https://cinc.sh/).

It is intended and recommended that CINC-auditor and this profile be executed from a __"runner"__ host (such as a DevOps orchestration server, an administrative management system, or a developer's workstation/laptop) against the target. This can be any Unix/Linux/MacOS or Windows runner host, with access to the Internet.

> [!TIP]
> **For the best security of the runner, always install on the runner the latest version of CINC-auditor and any other supporting language components.**

To install CINC-auditor on a UNIX/Linux/MacOS platform use the following command:

```bash
curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
```

To install CINC-auditor on a Windows platform (Powershell) use the following command:

```powershell
. { iwr -useb https://omnitruck.cinc.sh/install.ps1 } | iex; install -project cinc-auditor
```

To confirm successful install of cinc-auditor:

```
cinc-auditor -v
```

Latest versions and other installation options are available at the [CINC Auditor](https://cinc.sh/start/auditor/) site.

[top](#table-of-contents)

### Intended Usage

1. The latest `released` version of the profile is intended for use in A&A testing, as well as providing formal results to Authorizing Officials and Identity and Access Management (IAM)s. Please use the `released` versions of the profile in these types of workflows.

2. The `main` branch is a development branch that will become the next release of the profile. The `main` branch is intended for use in _developing and testing_ merge requests for the next release of the profile, and _is not intended_ to be used for formal and ongoing testing on systems.

[top](#table-of-contents)

### Container-Aware Testing

This profile is container-aware: controls that cannot apply inside a container (kernel parameters, bootloader, auditd, GUI, and similar host-only subsystems) detect the container environment and mark themselves `Not Applicable` automatically. This behavior is inherited from the upstream Ubuntu baseline and preserved in every overlay override, so the same profile can scan hosts, VMs, and container images.

[top](#table-of-contents)

### Tailoring to Your Environment

This profile uses InSpec Inputs to provide flexibility during testing. Inputs allow for customizing the behavior of Chef InSpec profiles.

InSpec Inputs are defined in the `inspec.yml` file. The `inputs` configured in this file are **profile definitions and defaults for the profile** and shouldn't be modified. InSpec provides several methods for customizing profile behaviors at run-time that do not require modifying the `inspec.yml` file itself (see [Using Customized Inputs](#using-customized-inputs)).

#### Inputs added by this overlay

| Input | Type | Default | Description |
|---|---|---|---|
| `sudo_accounts` | Array | `["debian"]` | Users expected to be in the `sudo` group. The upstream default is Ubuntu's cloud-image `ubuntu` user, which does not exist on Debian; this overlay substitutes Debian's cloud-image `debian` user. Override with your real administrative accounts. |

#### Upstream Ubuntu inputs

All inputs declared by the upstream Canonical Ubuntu 24.04 LTS STIG baseline remain available and keep their upstream defaults — set any of them at run time exactly as you would when running the Ubuntu profile. See the [upstream `inspec.yml`](https://github.com/mitre/canonical-ubuntu-24.04-lts-stig-baseline/blob/main/inspec.yml) for the full list.

One upstream input pair worth noting on Debian 13: the overlay's retargeted audit-watch controls (SV-270796, SV-270797, SV-270810) resolve their expected audit keynames through the upstream `audit_rule_keynames` / `audit_rule_keynames_overrides` inputs, falling back to the legacy path's keyname; if your site uses custom keynames for the trixie paths (`/var/run/faillock`, `/var/lib/lastlog/lastlog2.db`, `/var/log/wtmp.db`), add entries for them via `audit_rule_keynames_overrides`.

#### Using Customized Inputs

Customized inputs may be used at the CLI by providing an input file or a flag at execution time.

1. Using the `--input` flag

    Example: `[inspec or cinc-auditor] exec <my-profile.tar.gz> --input sudo_accounts='["admin1","admin2"]'`

2. Using the `--input-file` flag.

    Example: `[inspec or cinc-auditor] exec <my-profile.tar.gz> --input-file=<my_inputs_file.yml>`

> [!TIP]
> For additional information about `input` file examples reference the [MITRE SAF Training](https://mitre.github.io/saf-training/courses/beginner/06.html#input-file-example)

Chef InSpec Resources:

- [InSpec Profile Documentation](https://docs.chef.io/inspec/profiles/)
- [InSpec Inputs](https://docs.chef.io/inspec/profiles/inputs/)
- [inspec.yml](https://docs.chef.io/inspec/profiles/inspec_yml/)

[top](#table-of-contents)

### Testing the Profile Controls

The Gemfile provided contains all the necessary ruby dependencies for checking the profile controls. Install them by invoking the bundler command (must be in the same directory where the Gemfile is located):

```bash
bundle install
```

Linting and validating controls:

```bash
bundle exec rake inspec:check     # Validate the InSpec Profile
bundle exec rake lint             # Run RuboCop Linter
bundle exec rake pre_commit_checks  # Pre-commit checks (lint + check)
```

[top](#table-of-contents)

## Running the Profile

### Directly from Github

This option is best used when network connectivity is available and policies permit access to the hosting repository.

```bash
# Using `ssh` transport
bundle exec [inspec or cinc-auditor] exec https://github.com/mitre/debian-13-stig-baseline/archive/main.tar.gz --input-file=<your_inputs_file.yml> -t ssh://<hostname>:<port> --sudo --reporter=cli json:<your_results_file.json>
```

[top](#table-of-contents)

### Using a local Archive copy

If your runner is not always expected to have direct access to the profile's hosted location, use the following steps to create an archive bundle of this overlay and all of its dependent tests:

Git is required to clone the InSpec profile using the instructions below. Git can be downloaded from the [Git Web Site](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

When the **"runner"** host uses this profile overlay for the first time, follow these steps:

```bash
mkdir profiles
cd profiles
git clone https://github.com/mitre/debian-13-stig-baseline.git
bundle exec [inspec or cinc-auditor] archive debian-13-stig-baseline

# Using `ssh` transport
bundle exec [inspec or cinc-auditor] exec <name of generated archive> --input-file=<your_inputs_file.yml> -t ssh://<hostname>:<port> --sudo --reporter=cli json:<your_results_file.json>
```

For every successive run, follow these steps to always have the latest version of this profile baseline:

```bash
cd debian-13-stig-baseline
git pull
cd ..
bundle exec [inspec or cinc-auditor] archive debian-13-stig-baseline --overwrite
```

[top](#table-of-contents)

### Different Run Options

[Full exec options](https://docs.chef.io/inspec/cli/#options-3)

[top](#table-of-contents)

## Using Heimdall for Viewing Test Results

The JSON results output file can be loaded into **[Heimdall-Lite](https://heimdall-lite.mitre.org/)** or **[Heimdall-Server](https://github.com/mitre/heimdall2)** for a user-interactive, graphical view of the profile scan results.

Heimdall-Lite is a `browser only` viewer that allows you to easily view your results directly and locally rendered in your browser. Heimdall-Server is configured with a `data-services backend` allowing for data persistency to a database (PostgreSQL). For more detail on feature capabilities see [Heimdall Features](https://github.com/mitre/heimdall2?tab=readme-ov-file#features).

Heimdall can **_export your results into a DISA Checklist (CKL) file_** for easily uploading into eMass using the `Heimdall Export` function.

Depending on your environment restrictions, the [SAF CLI](https://saf-cli.mitre.org) can be used to run a local docker instance of Heimdall-Lite via the `saf view:heimdall` command.

Additionally both Heimdall applications can be deployed via docker, kubernetes, or the installation packages.

[top](#table-of-contents)

## FIPS 140 on Debian

Several controls in the upstream Ubuntu STIG concern FIPS 140 cryptography (SV-270667, SV-270668, SV-270669, SV-270670, SV-270671, SV-270739, SV-270744). It is possible to run the original Ubuntu profile checks against Debian and receive results, but note that even if the correct packages are present, Debian has no *validated* FIPS modules.

On Ubuntu Pro or RHEL, "FIPS mode" means that the system is using a stack of CMVP-validated cryptographic modules — NIST certificates naming the exact binary builds of OpenSSL, the kernel crypto API, and so on. FIPS 140 validation attaches to module builds and their certificates — not to algorithm names. So even though Debian is capable of running the kernel in FIPS mode and using appropriate algorithms for things like SSH libraries, Debian still has no CMVP-validated modules.

Therefore, even though Debian can technically be configured to pass the *literal text* of Ubuntu's STIG requirement for FIPS, it can't comply with its actual *intent*. The profile author has modified the FIPS-mode kernel check (SV-270744) in this overlay profile to *fail by default* accordingly.

### How this profile handles each FIPS-related check

- **SV-270667, SV-270668, SV-270669, SV-270670, SV-270671, SV-270739** verify approved-algorithm *configuration* (SSH ciphers/MACs/kex lists, SHA512 password hashing). These are real, distinct security properties a Debian system does or does not have, and they pass or fail on their own merits. They run exactly as upstream wrote them — this section is the note about their limitation.
- **SV-270744** ("must implement NIST FIPS-validated cryptography") checks the `fips=1` kernel posture **and then fails unconditionally** with a message pointing here. This is intentional: on Ubuntu, `fips_enabled=1` implies the validated Pro stack; on Debian it does not, and passing the upstream check would misrepresent an uncertified platform as compliant. Expect a permanent CAT I finding on every Debian scan. Deployments operating under a hard FIPS 140 mandate need a documented waiver/risk acceptance for it — or a platform that ships validated modules.

### What to do if you have a documented waiver for the FIPS requirements

If the test runner has a documented waiver for the FIPS requirements for a Debian deployment, they can write a local overlay for their specific environment to mark the FIPS requirements as Not Applicable. See the [MITRE SAF instructions for overlays](https://mitre.github.io/saf-training/courses/beginner/10.html).

[top](#table-of-contents)

## Authors

[MITRE Security Automation Framework Team](https://saf.mitre.org)

## NOTICE

© 2018-2025 The MITRE Corporation.

Approved for Public Release; Distribution Unlimited. Case Number 18-3678.

## NOTICE

MITRE hereby grants express written permission to use, reproduce, distribute, modify, and otherwise leverage this software to the extent permitted by the licensed terms provided in the LICENSE.md file included with this project.

## NOTICE

This software was produced for the U. S. Government under Contract Number HHSM-500-2012-00008I, and is subject to Federal Acquisition Regulation Clause 52.227-14, Rights in Data-General.

No other use other than that granted to the U. S. Government, or to those acting on behalf of the U. S. Government under that Clause is authorized without the express written permission of The MITRE Corporation.

For further information, please contact The MITRE Corporation, Contracts Management Office, 7515 Colshire Drive, McLean, VA  22102-7539, (703) 983-6000.

## NOTICE

[DISA STIGs are published by DISA IASE](https://public.cyber.mil/stigs/)
