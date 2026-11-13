# @summary
#   Installs and configures r10k on a node
# @param sources
#   The r10k sources to use
# @param r10k_version
#   The version of r10k to install (defaults to present)
class openvox_server::codemanagement (
  Array[Openvox_server::R10k_source] $sources,
  String $r10k_version = 'present',
) {
  $username = 'root'
  $r10k_bin = '/opt/puppetlabs/puppet/bin/r10k'

  package { 'r10k':
    ensure   => $r10k_version,
    provider => 'puppet_gem',
  }
  -> file { '/usr/local/bin/r10k':
    ensure => link,
    target => $r10k_bin,
  }
  -> file { '/etc/puppetlabs/r10k':
    ensure => 'directory',
  }
  -> file { '/etc/puppetlabs/r10k/r10k.yaml':
    content => template('openvox_server/r10k.yaml.erb'),
  }

  cron { 'r10k deploy environment --modules':
    ensure  => present,
    command => "/usr/bin/pkill --echo --signal 9 r10k; ${r10k_bin} deploy environment --modules 2>&1 | logger -t \"r10k_deploy_environment\"",
    user    => $username,
    minute  => '*/15',
    require => File['/etc/puppetlabs/r10k/r10k.yaml'],
  }
}
