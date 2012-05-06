# Define: openvpn::tunnel
#
# Manages openvpn tunnels creating an openvpn .conf file
#
# Parameters:
#
# [*mode*]
#   Sets general openvpn mode: client or server. Default: server
#
# [*remote*]
#   Sets remote host/IP. Needed in client mode. Default blank
#
# [*port*]
#   Default is 1194, change with multiple tunnels
#
# [*proto*]
#   Transport protocol: tcp or udp. Default: udp
#
# [*auth_type*]
#   Authentication method: key, ca
#
# [*auth_key*]
#   A static auth_key to use (Optional)
#
# [*dev*]
#   Device: tun for Ip routing , tap for bridging mode
#   Default: tun
#
# [*server*]
#   Server parameter. (in server mode)
#
# [*route*]
#   Route parameter
#
# [*template*]
#   Template to be used for the tunnel configuration.
#   Default is openvpn/tunnel.conf.erb
#   File: openvpn/templates/tunnel.conf.erb
#
# [*enable*]
#   If the tunnel is enabled or not.
#
define openvpn::tunnel (
  $auth_type,
  $mode         = 'server',
  $remote       = '',
  $port         = '1194',
  $auth_key     = '',
  $proto        = 'tcp',
  $dev          = 'tun',
  $server       = '10.8.0.0 255.255.255.0',
  $route        = '',
  $template     = 'openvpn/tunnel.conf.erb',
  $enable       = true ) {

  require openvpn

  $bool_enable=any2bool($enable)

  $manage_file = $bool_enable ? {
    true    => 'present',
    default => 'absent',
  }

  $real_proto = $proto ? {
    udp => 'udp',
    tcp => $mode ? {
      'server' => 'tcp-server',
      'client' => 'tcp-client',
    },
  }

  file { "openvpn_${name}.conf":
    ensure  => $manage_file,
    path    => "${openvpn::config_dir}/${name}.conf",
    mode    => $openvpn::config_file_mode,
    owner   => $openvpn::config_file_owner,
    group   => $openvpn::config_file_group,
    require => Package['openvpn'],
    notify  => Service['openvpn'],
    content => template($template),
  }

  if $auth_key != '' {
    file { "openvpn_${name}.key":
      ensure  => $manage_file,
      path    => "${openvpn::config_dir}/${name}.key",
      mode    => $openvpn::config_file_mode,
      owner   => $openvpn::config_file_owner,
      group   => $openvpn::config_file_group,
      require => Package['openvpn'],
      notify  => Service['openvpn'],
      content => $auth_key,
    }
  }

# Automatic monitoring of port and service
  if $openvpn::bool_monitor == true {
    monitor::port { "openvpn_${name}_${proto}_${port}":
      enable   => $bool_enable,
      protocol => $proto,
      port     => $port,
      target   => $openvpn::monitor_target,
      tool     => $openvpn::monitor_tool,
    }
    monitor::process { "openvpn_${name}_process":
      enable   => $bool_enable,
      process  => $openvpn::process,
      service  => $openvpn::service,
      pidfile  => "${openvpn::pid_file}/${name}.pid",
      user     => $openvpn::process_user,
      argument => "${name}.conf",
      tool     => $openvpn::monitor_tool,
    }
  }

# Automatic Firewalling
  if $openvpn::bool_firewall == true {
    firewall { "openvpn_${name}_${proto}_${port}":
      source      => $openvpn::firewall_source_real,
      destination => $openvpn::firewall_destination_real,
      protocol    => $proto,
      port        => $port,
      action      => 'allow',
      direction   => 'input',
      enable      => $bool_enable,
    }
  }

}
