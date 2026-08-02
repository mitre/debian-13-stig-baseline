# Debian 13 overlay of the Canonical Ubuntu 24.04 LTS STIG baseline.
#
# All controls from the upstream profile are included as-is except the spot
# overrides below, which implement the dispositions ruled on the 2p9.3 audit
# card (see its notes for the full control-status table and decision record).
#
# A control block inside include_controls REPLACES the upstream control's
# checks (verified empirically), so a control is only overlaid when its
# behavior on Debian must actually differ; anything that would merely add
# commentary runs pure upstream, with the nuance documented in the README
# (see "FIPS 140 on Debian" for the FIPS-family controls SV-270667,
# SV-270668, SV-270669, SV-270670, SV-270671, and SV-270739, which verify
# approved-algorithm configuration and run unmodified here).
include_controls 'canonical-ubuntu-24.04-lts-stig-baseline' do
  # SV-270744: the requirement is NIST FIPS-*validated* cryptography. On
  # Ubuntu, fips_enabled=1 implies the Ubuntu Pro validated module stack; on
  # Debian the same flag is reachable with stock, uncertified builds, so the
  # upstream proxy check would pass misleadingly. Ruling (ported from
  # debian-12's SV-260650): keep the kernel check as posture evidence and ADD
  # an assertion that always fails on Debian — a deliberate standing CAT I
  # finding so this profile never presents an uncertified platform as
  # FIPS-validated.
  control 'SV-270744' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    describe kernel_parameter('crypto.fips_enabled') do
      its('value') { should eq 1 }
    end

    describe 'NIST FIPS-validated cryptographic modules' do
      it 'are available and in use on this platform' do
        expect(false).to eq(true), 'Debian provides no CMVP/NIST-validated cryptographic modules. A fips=1 kernel and approved-algorithm configuration establish a FIPS-capable posture at best; they do not constitute the FIPS-validated cryptography this requirement mandates (see README, "FIPS 140 on Debian"). This is a permanent finding on Debian — deployments operating under a FIPS mandate need a documented waiver/risk acceptance or a platform with validated modules.'
      end
    end
  end

  # SV-278917: the upstream control verifies Ubuntu 24.04's identity and
  # support lifecycle (standard support -> Ubuntu Pro ESM). Rewritten for
  # Debian 13's identity and published lifecycle: Debian LTS covers trixie
  # through 2030-06-30 (free, part of the regular archive); beyond that,
  # Extended LTS (Freexian ELTS, commercial) runs through 2035-06-30 via its
  # own apt repository — the Debian analog of the upstream's `pro status`
  # subscription branch.
  control 'SV-278917' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    describe 'Debian release identity' do
      subject { os }
      its('name') { should eq 'debian' }
      its('release') { should match(/^13(\.|$)/) }
    end

    lts_eol = Time.new(2030, 6, 30, 23, 59, 59, '+00:00')
    elts_eol = Time.new(2035, 6, 30, 23, 59, 59, '+00:00')
    now = Time.now.utc

    if now <= lts_eol
      describe 'Debian 13 support lifecycle' do
        it 'is within the Debian LTS window' do
          expect(now <= lts_eol).to be true
        end
      end
    elsif now <= elts_eol
      # Beyond free LTS; vendor support requires the commercial Freexian
      # Extended LTS repository to be configured.
      elts_sources = command('grep -rsiE "deb\\.freexian\\.com/extended-lts|extended-lts" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null')

      describe 'Debian 13 Extended LTS (Freexian) apt source' do
        subject { elts_sources.stdout.strip }
        it 'is configured, providing vendor security support beyond the Debian LTS window' do
          expect(subject).to_not be_empty, "Debian LTS for trixie ended #{lts_eol.strftime('%Y-%m-%d')}; no Extended LTS (Freexian) apt source found, so this release no longer receives vendor security support."
        end
      end
    else
      describe 'Debian 13 support lifecycle' do
        it 'is within a vendor support window' do
          expect(now <= elts_eol).to be true, "All security support for Debian 13 (including Extended LTS) ended #{elts_eol.strftime('%Y-%m-%d')}; current date: #{now.strftime('%Y-%m-%d')}. Upgrade to a supported Debian release."
        end
      end
    end
  end

  # SV-270765: the upstream expectation (/var/log group-owned by "syslog") is
  # an Ubuntu rsyslog packaging convention — Ubuntu's rsyslog runs as the
  # syslog user and its packaging chgrps /var/log. Debian defines no syslog
  # group (base-passwd) and ships /var/log as root:root with rsyslog running
  # as root, so the upstream check can never pass and its fix command cannot
  # run. Same requirement (SRG-OS-000206: restrict access to error messages),
  # expressed in Debian's ownership convention.
  control 'SV-270765' do
    describe directory('/var/log') do
      it { should exist }
      its('group') { should eq 'root' }
    end
  end

  # SV-270769: same Ubuntu convention as SV-270765 — Debian has no syslog
  # user, and Debian's rsyslog writes /var/log/syslog as root. The upstream
  # not-exist escape is preserved: journald-only systems (the trixie default)
  # have no /var/log/syslog at all, which upstream treats as passing.
  control 'SV-270769' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    describe.one do
      describe file('/var/log/syslog') do
        its('owner') { should cmp 'root' }
      end
      describe file('/var/log/syslog') do
        it { should_not exist }
      end
    end
  end

  # SV-270796: trixie's shadow package dropped the faillog tool and nothing
  # creates /var/log/faillog anymore, so the upstream watch rule targets a
  # file that never exists. Debian 13 records authentication failures via
  # pam_faillock in per-user files under /var/run/faillock (faillock.conf
  # "dir" default), so the audit watch is retargeted there — the directory
  # must be recreated at boot (e.g. systemd-tmpfiles) for the rule to load.
  # The expected keyname stays input-driven, falling back to the upstream
  # path's entry so the stock keyname table applies unchanged.
  control 'SV-270796' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    audit_target = '/var/run/faillock'
    keynames = input('audit_rule_keynames').merge(input('audit_rule_keynames_overrides'))
    keyname = keynames[audit_target] || keynames['/var/log/faillog']

    describe 'Audit watch' do
      it "#{audit_target} is audited properly" do
        audit_rule = auditd.file(audit_target)
        expect(audit_rule).to exist
        expect(audit_rule.permissions.flatten).to include('w', 'a')
        expect(audit_rule.key.uniq).to include(keyname)
      end
    end
  end

  # SV-270797: trixie removed classic /var/log/lastlog (Y2038) in favor of
  # lastlog2; the login-tracking database is /var/lib/lastlog/lastlog2.db
  # (lastlog2(8), trixie manpage), so the audit watch is retargeted there.
  control 'SV-270797' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    audit_target = '/var/lib/lastlog/lastlog2.db'
    keynames = input('audit_rule_keynames').merge(input('audit_rule_keynames_overrides'))
    keyname = keynames[audit_target] || keynames['/var/log/lastlog']

    describe 'Audit watch' do
      it "#{audit_target} is audited properly" do
        audit_rule = auditd.file(audit_target)
        expect(audit_rule).to exist
        expect(audit_rule.permissions.flatten).to include('w', 'a')
        expect(audit_rule.key.uniq).to include(keyname)
      end
    end
  end

  # SV-270810: trixie removed classic /var/log/wtmp (Y2038) in favor of
  # wtmpdb; the session database is /var/log/wtmp.db (wtmpdb(8), trixie
  # manpage), so the audit watch is retargeted there. /var/run/utmp survives
  # unchanged, so SV-270811 runs pure upstream.
  control 'SV-270810' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    audit_target = '/var/log/wtmp.db'
    keynames = input('audit_rule_keynames').merge(input('audit_rule_keynames_overrides'))
    keyname = keynames[audit_target] || keynames['/var/log/wtmp']

    describe 'Audit watch' do
      it "#{audit_target} is audited properly" do
        audit_rule = auditd.file(audit_target)
        expect(audit_rule).to exist
        expect(audit_rule.permissions.flatten).to include('w', 'a')
        expect(audit_rule.key.uniq).to include(keyname)
      end
    end
  end
end
