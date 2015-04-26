# Class openvpn::repository
#
class openvpn::repository (
) {

  if ( $::operatingsystem =~ /(?i:Debian|Ubuntu|Mint)/ ) {

    # mapping derived from:
    # https://community.openvpn.net/openvpn/wiki/OpenvpnSoftwareRepos
    case $::lsbdistcodename {
      natty, oneiric: { $distro = 'lucid' }
      default: { $distro = $::lsbdistcodename }
    }

    if $openvpn::bool_firewall {
      firewall { 'openvpn-repository':
        destination => '173.192.224.173', # repos.openvpn.net
        protocol    => 'tcp',
        port        => 80,
        direction   => 'output',
        enable_v6   => false,
      }
    }

    apt::repository { 'openvpn':
      url        => "http://repos.openvpn.net/repos/apt/${distro}-snapshots",
      distro     => $distro,
      repository => 'main',
    }

    if $openvpn::bool_firewall {
      firewall { 'openvpn-repository-key':
        destination => '173.192.224.173', # repos.openvpn.net
        protocol    => 'tcp',
        port        => 443,
        direction   => 'output',
        enable_v6   => false,
      }
    }

    apt::key { '2048R/E158C569':
      url => 'https://swupdate.openvpn.net/repos/repo-public.gpg',
    }

  }

}
