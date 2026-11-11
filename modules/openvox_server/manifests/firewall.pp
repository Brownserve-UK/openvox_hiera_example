# @summary
#   Configures the iptables firewall on the OpenVox server to allow expected services
# @param enable_openvoxdb_http
#   Whether to allow OpenVoxDB HTTP traffic (default: false)
class openvox_server::firewall (
  Boolean $enable_openvoxdb_http = false
) {
  Firewall {
    require => undef,
  }

  firewall { '000 accept all icmp':
    proto => 'icmp',
    jump  => 'accept',
  }
  -> firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    jump    => 'accept',
  }
  -> firewall { '002 reject local traffic not on loopback interface':
    iniface     => '! lo',
    proto       => 'all',
    destination => '127.0.0.1/8',
    jump        => 'reject',
  }
  -> firewall { '003 accept related established rules':
    proto => 'all',
    state => ['RELATED', 'ESTABLISHED'],
    jump  => 'accept',
  }
  -> firewall { '004 accept SSH':
    proto => 'tcp',
    dport => 22,
    jump  => 'accept',
  }
  -> firewall { '005 allow 8081 (OpenVoxDB HTTPS)':
    proto => 'tcp',
    dport => 8081,
    jump  => 'accept',
  }
  -> firewall { '006 allow 8140 (OpenVox server node communication HTTPS)':
    proto => 'tcp',
    dport => 8140,
    jump  => 'accept',
  }
  -> firewall { '999 drop all':
    proto  => 'all',
    jump   => 'drop',
    before => undef,
  }
  if ($enable_openvoxdb_http) {
    firewall { '005.5 allow 8080 (OpenVoxDB HTTP)':
      proto => 'tcp',
      dport => 8080,
      jump  => 'accept',
    }
  }
}
