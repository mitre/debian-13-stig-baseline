# debian-13-stig-baseline

STIG-ready InSpec validation baseline for Debian 13 (trixie).

There is no DISA STIG for Debian. This profile is an overlay of the
[Canonical Ubuntu 24.04 LTS STIG baseline](https://github.com/mitre/canonical-ubuntu-24.04-lts-stig-baseline)
maintained by the MITRE SAF team, chosen because Ubuntu 24.04 is the newest
STIG-covered release and the closest match to Debian 13 (kernel 6.x, systemd
25x, modern PAM). Debian 13 is somewhat newer than 24.04 (e.g. OpenSSL 3.5 vs
3.0), which individual overlay controls account for. Ubuntu-specific checks are
adapted or marked not applicable for Debian in `controls/overlay.rb`.

This is **not** DISA-published content. It is a STIG-ready baseline mapped to
the same GPOS SRG requirements the Ubuntu STIG is derived from.

## Running

```sh
inspec exec . -t ssh://user@debian13-host --input-file inputs.yml --reporter cli json:results.json
```

## Overlay structure

- `inspec.yml` — profile metadata; declares the pinned upstream dependency
- `controls/overlay.rb` — `include_controls` of the upstream profile plus
  per-control Debian overrides
