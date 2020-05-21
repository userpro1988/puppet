# Class: profile::druid::historical
#
class profile::druid::historical(
    $properties         = hiera('profile::druid::historical::properties', {}),
    $env                = hiera('profile::druid::historical::env', {}),
    $daemon_autoreload  = hiera('profile::druid::daemons_autoreload', true),
    $ferm_srange        = hiera('profile::druid::ferm_srange', '$DOMAIN_NETWORKS'),
    $monitoring_enabled = hiera('profile::druid::historical::monitoring_enabled', false),
) {

    require ::profile::druid::common

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Druid Broker process.
    if $monitoring_enabled {
        require ::profile::druid::monitoring::historical
        $monitoring_java_opts = $::profile::druid::monitoring::historical::java_opts
    } else {
        $monitoring_java_opts = undef
    }

    # The suggestion for the Historical daemon is to set the
    # druid.processing.numThreads to ncores.
    # https://druid.apache.org/docs/latest/operations/basic-cluster-tuning.html#process-specific-guidelines
    # This is useful since we have historicals running on different hw.
    # As consequence, the MaxDirectMemorySize java opt needs to be set according to a formula, otherwise
    # the Historical will refuse to start.
    if !has_key($properties, 'druid.processing.numThreads') {
        $extra_properties = {
            'druid.processing.numThreads' => $facts['processors']['count']
        }
        # max direct memory = druid.processing.buffer.sizeBytes[268,435,456] * (druid.processing.numMergeBuffers[10] + druid.processing.numThreads[64] + 1)
        $max_direct_memory = Integer($properties['druid.processing.buffer.sizeBytes']) * (Integer($properties['druid.processing.numMergeBuffers']) + Integer($facts['processors']['count']) + 1)
        $max_direct_memory_java_opt = "-XX:MaxDirectMemorySize=${max_direct_memory}"
    } else {
        $extra_properties = {}
        $max_direct_memory = undef
    }

    if $monitoring_java_opts or $max_direct_memory_java_opt {
        if $env['DRUID_EXTRA_JVM_OPTS'] {
            $druid_extra_env_var = {
                'DRUID_EXTRA_JVM_OPTS' => "${env['DRUID_EXTRA_JVM_OPTS']} ${max_direct_memory_java_opt} ${monitoring_java_opts}"
            }
        } else {
            $druid_extra_env_var = {
                'DRUID_EXTRA_JVM_OPTS' => "${max_direct_memory} ${monitoring_java_opts}"
            }
        }
    }

    # Druid historical Service
    class { '::druid::historical':
        properties       => merge($properties, $extra_properties),
        env              => merge($env, $druid_extra_env_var),
        should_subscribe => $daemon_autoreload,
    }

    ferm::service { 'druid-historical':
        proto  => 'tcp',
        port   => $::druid::historical::runtime_properties['druid.port'],
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        nrpe::monitor_service { 'druid-historical':
            description  => 'Druid historical',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a \'io.druid.cli.Main server historical\'',
            critical     => false,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid',
        }
    }
}
