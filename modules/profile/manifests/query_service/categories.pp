# = Class: profile::query_service::categories
#
# This class defines a meta-class that pulls in all the query_service profiles
# necessary for a query service installation servicing the commons.wikimedia.org
# dataset.
#
# This additionally provides a location for defining datasource specific
# configuration, such as if geo support is necessary. This kind of
# configuration doesn't end up fitting in hiera as we have multiple blazegraph
# instances per host (preventing configuration by profile), and multiple roles
# per datasource (preventing configuration by role).
class profile::query_service::categories(
    String $username = lookup('profile::query_service::username'),
    Stdlib::Unixpath $package_dir = hiera('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = hiera('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = hiera('profile::query_service::log_dir'),
    String $deploy_name = hiera('profile::query_service::deploy_name'),
    Stdlib::Port $logstash_logback_port = hiera('logstash_logback_port'),
    Boolean $use_deployed_config = hiera('profile::query_service::blazegraph_use_deployed_config', false),
    Array[String] $options = hiera('profile::query_service::blazegraph_options'),
    Array[String] $extra_jvm_opts = hiera('profile::query_service::blazegraph_extra_jvm_opts'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    String $contact_groups = hiera('contactgroups', 'admins'),
    String $federation_user_agent = lookup('profile::query_service::federation_user_agent'),
) {
    require ::profile::query_service::common
    include ::profile::query_service::monitor::categories

    $instance_name = "${deploy_name}-categories"
    $blazegraph_port = 9990
    $prometheus_port = 9194
    $prometheus_agent_port = 9103

    profile::query_service::blazegraph { $instance_name:
        journal                => 'categories',
        # initial namespace for categories, this will not be used as importing
        # the categories should always create a new namespace suffixed with the
        # date and tracked in the aliases.map file
        blazegraph_main_ns     => 'categories',
        username               => $username,
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        log_dir                => $log_dir,
        deploy_name            => $deploy_name,
        logstash_logback_port  => $logstash_logback_port,
        heap_size              => '8g',
        use_deployed_config    => $use_deployed_config,
        options                => $options,
        extra_jvm_opts         => $extra_jvm_opts,
        prometheus_nodes       => $prometheus_nodes,
        contact_groups         => $contact_groups,
        monitoring_enabled     => true, # ????
        sparql_query_stream    => undef,
        event_service_endpoint => undef,
        blazegraph_port        => $blazegraph_port,
        prometheus_port        => $prometheus_port,
        prometheus_agent_port  => $prometheus_agent_port,
        config_file_name       => 'RWStore.categories.properties',
        use_geospatial         => false,
        federation_user_agent  => $federation_user_agent,
    }
}
