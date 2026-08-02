# debian-13-stig-baseline

STIG-ready InSpec validation baseline for Debian 13 (trixie).

There is no DISA STIG for Debian. This profile is an overlay of the [Canonical Ubuntu 24.04 LTS STIG baseline](https://github.com/mitre/canonical-ubuntu-24.04-lts-stig-baseline) maintained by the MITRE SAF team, chosen because Ubuntu 24.04 is the newest STIG-covered release and the closest match to Debian 13 (kernel 6.x, systemd 25x, modern PAM). Debian 13 is somewhat newer than 24.04 (e.g. OpenSSL 3.5 vs 3.0), which individual overlay controls account for. Ubuntu-specific checks are adapted or marked not applicable for Debian in `controls/overlay.rb`.

This is **not** DISA-published content. It is a STIG-ready baseline mapped to the same GPOS SRG requirements the Ubuntu STIG is derived from.

## Running

```sh
inspec exec . -t ssh://user@debian13-host --input-file inputs.yml --reporter cli json:results.json
```

## Overlay structure

- `inspec.yml` — profile metadata; declares the pinned upstream dependency
- `controls/overlay.rb` — `include_controls` of the upstream profile plus per-control Debian overrides

## FIPS 140 on Debian

Several controls in the upstream Ubuntu STIG concern FIPS 140 cryptography (SV-270667, SV-270668, SV-270669, SV-270670, SV-270671, SV-270739, SV-270744). It is possible to run the original Ubuntu profile checks against Debian and receive results, but note that even if the correct packages are present, Debian has no *validated* FIPS modules.

On Ubuntu Pro or RHEL, "FIPS mode" means that the system is using a stack of CMVP-validated cryptographic modules — NIST certificates naming the exact binary builds of OpenSSL, the kernel crypto API, and so on. FIPS 140 validation attaches to module builds and their certificates — not to algorithm names. So even though Debian is capable of running the kernel in FIPS mode and using appropriate algorithms for things like SSH libraries, Debian still has no CMVP-validated modules.

Therefore, even though Debian can technically be configured to pass the *literal text* of Ubuntu's STIG requirement for FIPS, it can't comply with its actual *intent*. The profile author has modified the FIPS-mode kernel check (SV-270744) in this overlay profile to *fail by default* accordingly.

### How this profile handles each FIPS-related check

- **SV-270667, SV-270668, SV-270669, SV-270670, SV-270671, SV-270739** verify approved-algorithm *configuration* (SSH ciphers/MACs/kex lists, SHA512 password hashing). These are real, distinct security properties a Debian system does or does not have, and they pass or fail on their own merits. They run exactly as upstream wrote them — this section is the note about their limitation.
- **SV-270744** ("must implement NIST FIPS-validated cryptography") checks the `fips=1` kernel posture **and then fails unconditionally** with a message pointing here. This is intentional: on Ubuntu, `fips_enabled=1` implies the validated Pro stack; on Debian it does not, and passing the upstream check would misrepresent an uncertified platform as compliant. Expect a permanent CAT I finding on every Debian scan. Deployments operating under a hard FIPS 140 mandate need a documented waiver/risk acceptance for it — or a platform that ships validated modules.

### What to do if you have a documented waiver for the FIPS requirements

If the test runner has a documented waiver for the FIPS requirements for a Debian deployment, they can write a local overlay for their specific environment to mark the FIPS requirements as Not Applicable. See the [MITRE SAF instructions for overlays](https://mitre.github.io/saf-training/courses/beginner/10.html).
