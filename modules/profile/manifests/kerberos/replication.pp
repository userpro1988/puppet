# Class: profile::kerberos::replication
#
# Configure the current Kerberos master/primary and its slaves to
# replicate the KDC database periodically.
# There are two options:
# 1) the host is the current Kerberos master/primary, so it needs to
#    run a script (via systemd timer) that periodically dumps the KDC database
#    and replicate it via kprop to all the Kerberos slaves.
# 2) the host is a Kerberos slave, so it needs to run the kpropd daemon, to be
#    able to receive updates from the master (via kprop) when available.
#    Only the slaves needs to be configured with a specific kpropd.acl config file.
#
# This profile requires to run on a host with a KDC running, and it also needs the
# kprop tool that is provided by the krb5-admin-server package.
#
class profile::kerberos::replication (
    Array[Stdlib::Fqdn] $krb_kdc_servers = lookup('kerberos_kdc_servers'),
    Stdlib::Fqdn $krb_kadmin_primary = lookup('kerberos_kadmin_server_primary'),
    Optional[Boolean] $monitoring_enabled = lookup('profile::kerberos::replication::monitoring_enabled', { 'default_value' => false }),
) {
    if $trusted['certname'] != $krb_kadmin_primary {
        package { 'krb5-kpropd':
            ensure => present,
        }

        ferm::service { 'kerberos_kpropd_tcp':
            proto  => 'tcp',
            port   => '754',
            srange => "(@resolve((${trusted['certname']})) @resolve((${trusted['certname']}), AAAA))",
        }

        file { '/etc/krb5kdc/kpropd.acl':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            conent => template('profile/kerberos/kpropd.acl.erb'),
            before => Package['krb5-kpropd'],
        }
    } else {
        package { 'krb5-kpropd':
            ensure => absent,
        }

        service { 'krb5-kpropd':
            ensure => stopped,
        }

        file { '/etc/krb5kdc/kpropd.acl':
            ensure => absent,
        }

        $krb_kdc_slave_servers = $krb_kdc_servers.filter |$krb_kdc_server| { $krb_kdc_server != $krb_kadmin_primary }
        file { '/usr/local/sbin/replicate_krb_database':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0550',
            content => template('profile/kerberos/replicate_krb_database.erb'),
        }

        systemd::timer::job { 'replicate-krb-database':
            description        => 'Replication of the KDC database to the Kerberos slaves',
            command            => '/usr/local/sbin/replicate_krb_database',
            interval           => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:00:00'
            },
            user               => 'root',
            monitoring_enabled => $monitoring_enabled,
            logging_enabled    => false,
            require            => [
                File['/usr/local/sbin/replicate_krb_database'],
                File['/srv/backup'],
            ],
        }
    }
}