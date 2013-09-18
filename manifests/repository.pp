class openvpn::repository (
) {

  if ( $::operatingsystem =~ /(?i:Debian:Ubuntu|Mint)/ ) {

    # mapping derived from:
    # https://community.openvpn.net/openvpn/wiki/OpenvpnSoftwareRepos
    case $::lsbdistcodename {
      natty, oneiric: { $distro = 'lucid' }
      default: { $distro = $::lsbdistcodename }
    }

    apt::repository { 'openvpn':
      url        => 'http://swupdate.openvpn.net/repos/apt/squeeze-stable',
      distro     => 'squeeze',
      repository => 'main',
    }

    apt::key { '2048R/E158C569':
      url => 'http://swupdate.openvpn.net/repos/repo-public.gpg',
    }
  }

}
