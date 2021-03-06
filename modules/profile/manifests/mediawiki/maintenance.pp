# mediawiki maintenance server
class profile::mediawiki::maintenance {
    # In order to be able to use the conftool-aware wrapper, we need to access
    # such data easily (on disk).
    require ::profile::conftool::state

    # httpd for noc.wikimedia.org
    class { '::httpd':
        modules => ['rewrite', 'headers'],
    }

    ::httpd::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }

    # Deployment
    include ::scap::scripts

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }

    $ensure = mediawiki::state('primary_dc') ? {
        $::site => 'present',
        default => 'absent',
    }

    file { '/usr/local/bin/mw-cli-wrapper':
        source => 'puppet:///modules/profile/mediawiki/maintenance/mw-cli-wrapper.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555'
    }

    # MediaWiki maintenance scripts (cron jobs)
    include ::profile::mediawiki::maintenance::wikidata
    include ::profile::mediawiki::maintenance::growthexperiments
    include ::profile::mediawiki::maintenance::pagetriage
    include ::profile::mediawiki::maintenance::translationnotifications
    include ::profile::mediawiki::maintenance::updatetranslationstats
    include ::profile::mediawiki::maintenance::echo_mail_batch
    include ::profile::mediawiki::maintenance::parsercachepurging
    include ::profile::mediawiki::maintenance::cleanup_upload_stash
    include ::profile::mediawiki::maintenance::update_flaggedrev_stats
    include ::profile::mediawiki::maintenance::refreshlinks
    include ::profile::mediawiki::maintenance::update_special_pages
    include ::profile::mediawiki::maintenance::purge_abusefilter
    include ::profile::mediawiki::maintenance::purge_checkuser
    include ::profile::mediawiki::maintenance::purge_expired_userrights
    include ::profile::mediawiki::maintenance::purge_old_cx_drafts
    include ::profile::mediawiki::maintenance::purge_securepoll
    include ::profile::mediawiki::maintenance::db_lag_stats
    include ::profile::mediawiki::maintenance::cirrussearch
    include ::profile::mediawiki::maintenance::generatecaptcha
    include ::profile::mediawiki::maintenance::pageassessments
    class { 'mediawiki::maintenance::uploads': ensure => $ensure }
    include ::profile::mediawiki::maintenance::readinglists
    include ::profile::mediawiki::maintenance::initsitestats
    include ::profile::mediawiki::maintenance::startupregistrystats

    # Include the cache warmup script; requires node and conftool
    require ::profile::conftool::client
    class { '::mediawiki::maintenance::cache_warmup':
        ensure => present,
    }

    # backup home directories to bacula, people work on these
    include ::profile::backup::host
    backup::set {'home': }

    # (T17434) Periodical run of currently disabled special pages
    include ::profile::mediawiki::maintenance::updatequerypages

    # Readline support for PHP maintenance scripts (T126262)
    require_package('php-readline')

    # GNU version of 'time' provides extra info like peak resident memory
    # anomie needs it, as opposed to the shell built-in time command
    require_package('time')

    # T112660 - kafka support
    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this but don't
    # run any daemons.  To use eventlogging code,
    # add /srv/deployment/eventlogging/eventlogging
    # to your PYTHONPATH or sys.path.
    include ::eventlogging

    rsync::quickdatacopy { 'home-mwmaint':
        ensure      => present,
        auto_sync   => false,
        source_host => 'mwmaint2001.codfw.wmnet',
        dest_host   => 'mwmaint1002.eqiad.wmnet',
        module_path => '/home',
    }

    # T199124
    $motd_ensure = $ensure ? {
        'present' => 'absent',
        'absent'  => 'present',
        default   => 'present',
    }

    motd::script { 'inactive_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('profile/mediawiki/maintenance/inactive.motd.erb'),
    }

    rsync::quickdatacopy { 'mwmaint-miscweb':
        ensure      => present,
        auto_sync   => false,
        source_host => 'mwmaint1002.eqiad.wmnet',
        dest_host   => 'miscweb2002.codfw.wmnet',
        module_path => '/home',
    }
}
