define openvpn::client (
  $cn,
  $tunnelName,
  $push         = '',
  $pushReset    = false,
  $iroute       = '',
  $ifconfigPush = '',
  $config       = ''
) {

  file { "${openvpn::config_dir}/${tunnelName}/ccd/${cn}":
    ensure  => file,
    mode    => $openvpn::config_file_mode,
    owner   => $openvpn::config_file_owner,
    group   => $openvpn::config_file_group,
    content => template('openvpn/ccd.conf.erb'),
    require => File[ "${openvpn::config_dir}/${tunnelName}/ccd" ]
  }

  exec { "openvpn-client-gen-cert-${name}":
    command  => ". ./vars && KEY_CN=${cn} ./pkitool ${cn}",
    cwd      => "${openvpn::config_dir}/${tunnelName}/easy-rsa",
    creates  => "${openvpn::config_dir}/${tunnelName}/easy-rsa/keys/${cn}.crt",
    provider => 'shell',
    notify   => Service['openvpn'],
    require  => Exec["openvpn-tunnel-rsa-ca-${tunnelName}"]
  }

}
