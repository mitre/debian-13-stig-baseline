include_controls 'canonical-ubuntu-24.04-lts-stig-baseline' do
  # SV-270744: Debian ships no FIPS-validated modules, so this keeps the
  # kernel-flag evidence but always fails; see README, "FIPS 140 on Debian".
  control 'SV-270744' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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

  # SV-278917: rewritten for Debian 13's identity and published lifecycle —
  # free Debian LTS to 2030-06-30, then Freexian Extended LTS to 2035-06-30.
  control 'SV-278917' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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
      # Past free LTS: vendor support requires the commercial Freexian ELTS repo.
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

  # SV-270765: the "syslog" group on /var/log is an Ubuntu rsyslog packaging
  # convention; Debian has no syslog group and ships /var/log as root:root.
  control 'SV-270765' do
    describe directory('/var/log') do
      it { should exist }
      its('group') { should eq 'root' }
    end
  end

  # SV-270769: same as SV-270765 — Debian's rsyslog writes /var/log/syslog as
  # root; the upstream not-exist escape for journald-only systems is preserved.
  control 'SV-270769' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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

  # SV-270796: trixie dropped faillog; auth failures now land in pam_faillock's
  # /var/run/faillock, so the audit watch is retargeted there.
  control 'SV-270796' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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

  # SV-270797: trixie replaced lastlog with lastlog2 (Y2038), so the audit
  # watch is retargeted to /var/lib/lastlog/lastlog2.db.
  control 'SV-270797' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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

  # SV-270810: trixie replaced wtmp with wtmpdb (Y2038), so the audit watch is
  # retargeted to /var/log/wtmp.db; /var/run/utmp survives, so SV-270811 runs
  # pure upstream.
  control 'SV-270810' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !virtualization.container_system?
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
