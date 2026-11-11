# @summary Installs and configures OpenVox Server on a node
#
# @param openvox_majorversion
#   The major version of OpenVox to install (only 8 is supported)
# @param openvox_agent_environment
#   The environment set under the [agent] section in puppet.conf
# @param puppet_user
#   The user to run OpenVox as
# @param puppet_group
#   The group to run OpenVox as
# @param manage_agent_service
#   Whether to manage the agent service
# @param hiera_yaml_path
#   The path to the global hiera.yaml, used by both the hiera and puppet classes
# @param install_openvoxdb
#   Whether to install OpenVoxDB, leave off when bootstrapping
# @param openvoxdb_server
#   The hostname of the OpenVoxDB server
# @param openvoxdb_http_interface
#   The interface OpenVoxDB listens on for HTTP
# @param dns_alt_names
#   Alternate names for the server certificate
# @param autosign_entries
#   Certificates to automatically sign
class openvox_server (
  Integer $openvox_majorversion,
  Optional[String] $openvox_agent_environment = undef,
  String $puppet_user = 'puppet',
  String $puppet_group = 'puppet',
  Boolean $manage_agent_service = true,
  Stdlib::Unixpath $hiera_yaml_path = "${settings::codedir}/hiera.yaml",
  Boolean $install_openvoxdb = true,
  String $openvoxdb_server = $facts['networking']['fqdn'],
  String $openvoxdb_http_interface = 'localhost',
  Optional[Array] $dns_alt_names = undef,
  Optional[Array] $autosign_entries = undef,
) {
  include openvox_server::codemanagement
  include openvox_server::firewall

  group { $puppet_group:
    ensure => present,
  }
  -> user { $puppet_user:
    ensure => present,
    groups => $puppet_group,
    shell  => '/usr/sbin/nologin',
  }

  if ($manage_agent_service == false) {
    $runmode = 'unmanaged'
  } else {
    $runmode = 'service'
  }

  case $openvox_majorversion {
    8: {
      $openvox_agent_package_version = "8.32.0-1+ubuntu${facts['os']['release']['full']}"
      $openvox_server_package_version = "8.18.0-1+ubuntu${facts['os']['release']['full']}"
      $openvoxdb_package_version = "8.18.0-1+ubuntu${facts['os']['release']['full']}"
      $openvox_server_version = '8.18.0'
      $hiera_version = '5'
      $hiera_hierarchies = []
      $cipher_suites = [
        'TLS_AES_128_GCM_SHA256',
        'TLS_AES_256_GCM_SHA384',
        'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
        'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
      ]
    }
    default: {
      fail("Unsupported OpenVox version: ${openvox_majorversion}.")
    }
  }

  if ($install_openvoxdb) {
    class { 'openvoxdb':
      node_ttl           => '14d',
      node_purge_ttl     => '30d',
      report_ttl         => '5d',
      java_args          => {
        '-Xmx' => '1g',
        '-Xms' => '1g',
      },
      puppetdb_version   => $openvoxdb_package_version,
      postgres_version   => '16',
      cipher_suites      => join($cipher_suites, ', '),
      ssl_deploy_certs   => true,
      ssl_dir            => '/etc/puppetlabs/puppetdb/ssl',
      ssl_set_cert_paths => true,
      listen_address     => $openvoxdb_http_interface,
    }
    $puppet_require = [Class['openvoxdb']]

    class { 'openvoxdb::master::config':
      puppetdb_server          => $openvoxdb_server,
      manage_storeconfigs      => false,
      restart_puppet           => false,
      terminus_package_version => $openvoxdb_package_version,
      require                  => $puppet_require,
    }
    Class['openvoxdb::master::puppetdb_conf'] ~> Class['puppet::server::service']

    $server_reports = 'puppetdb'
    $server_storeconfigs = true
  }
  else {
    $puppet_require = undef
    $server_reports = 'store'
    $server_storeconfigs = false
  }

  if $trusted['extensions']['pp_environment'] == 'live' {
    $puppet_tuning_parameters = {
      server_max_active_instances => 2,
      server_jvm_min_heap_size    => '1G',
      server_jvm_max_heap_size    => '2G',
    }
  }
  else {
    $puppet_tuning_parameters = {
      server_max_active_instances => 1,
      server_jvm_min_heap_size    => '512m',
      server_jvm_max_heap_size    => '1G',
    }
  }

  class { 'puppet':
    server                      => true,
    version                     => $openvox_agent_package_version,
    runmode                     => $runmode,
    server_version              => $openvox_server_package_version,
    server_puppetserver_version => $openvox_server_version,
    server_cipher_suites        => $cipher_suites,
    environment                 => $openvox_agent_environment,
    server_foreman              => false,
    server_external_nodes       => '',
    server_reports              => $server_reports,
    server_storeconfigs         => $server_storeconfigs,
    server_user                 => $puppet_user,
    server_group                => $puppet_group,
    server_common_modules_path  => [],
    hiera_config                => $hiera_yaml_path,
    dns_alt_names               => $dns_alt_names,
    autosign_entries            => $autosign_entries,
    additional_settings         => {
      usecacheonfailure => false,
    },
    usecacheonfailure           => false,
    server_manage_user          => false,
    *                           => $puppet_tuning_parameters,
    require                     => $puppet_require,
  }

  class { 'hiera':
    hiera_yaml           => $hiera_yaml_path,
    hiera_version        => $hiera_version,
    hierarchy            => $hiera_hierarchies,
    eyaml                => true,
    manage_eyaml_package => false,
    datadir              => '/etc/puppetlabs/code/environments',
    eyaml_datadir        => '/etc/puppetlabs/code/environments',
    datadir_manage       => false,
    provider             => 'puppetserver_gem',
    create_symlink       => false,
    master_service       => 'puppetserver',
    require              => User[$puppet_user],
  }

  file { '/opt/puppetlabs/bin/eyaml':
    ensure  => link,
    target  => '/opt/puppetlabs/puppet/bin/eyaml',
    require => Class['hiera'],
  }
}
