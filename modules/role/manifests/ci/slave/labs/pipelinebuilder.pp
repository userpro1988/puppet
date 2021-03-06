# == Class role::ci:slave::labs::pipelinebuilder
#
# Experimental Jenkins slave instance for performing CD pipeline builds using
# Blubber/Docker and isolated deployments/testing using Helm.
#
# filtertags: labs-project-integration
class role::ci::slave::labs::pipelinebuilder {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs::pipelinebuilder':
        description => 'CI Jenkins slave for building CD pipeline images' }

    include profile::ci::slave::labs::common
    include profile::ci::gitcache
    include profile::ci::pipeline::builder
}
