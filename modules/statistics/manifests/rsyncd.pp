# == Class statistics::rsyncd
# Sets up rsyncd and common modules
# for statistic servers.  Currently
# this is read/write between statistic
# servers in /srv or /a.
#
# == Parameters
#   path        - string.  Base path to allow rsync access.  Should probably be /srv or /a.
#   hosts_allow - array.   Hosts to grant rsync access.
class statistics::rsyncd($path, $hosts_allow)
{
    Class['::statistics'] -> Class['statistics::rsyncd']

    # this uses modules/rsync to
    # set up an rsync daemon service
    class { '::rsync::server':
        # the default timeout of 300 is too low
        timeout => 1000,
    }

    # Set up an rsync module
    # (in /etc/rsyncd.conf) for /home.
    rsync::server::module { 'home':
        path        => '/home',
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
        auto_ferm   => true,
    }

    # Set up an rsync module
    # (in /etc/rsyncd.conf) for /srv.
    rsync::server::module { 'srv':
        path        => $path,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
        auto_ferm   => true,
    }
}
