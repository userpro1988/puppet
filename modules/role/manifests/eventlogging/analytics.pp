class role::eventlogging::analytics {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::eventlogging::analytics::processor
}
