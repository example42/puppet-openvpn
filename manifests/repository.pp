class openvpn::repository (
) {

  if ( $::operatingsystem =~ /(?i:Debian|Ubuntu|Mint)/ ) {

    # mapping derived from:
    # https://community.openvpn.net/openvpn/wiki/OpenvpnSoftwareRepos
    case $::lsbdistcodename {
      natty, oneiric: { $distro = 'lucid' }
      default: { $distro = $::lsbdistcodename }
    }

    apt::repository { 'openvpn':
      url        => "http://repos.openvpn.net/repos/apt/${distro}-snapshots",
      distro     => $distro,
      repository => 'main',
    }

    apt::key { '2048R/E158C569':
      url => 'https://swupdate.openvpn.net/repos/repo-public.gpg',
    }
  }

}
