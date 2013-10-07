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
#   Authentication method: key, tls-server, tls-client
#
# [*auth_key*]
#   Source of the key file (Used when auth_type = key)
#   Used as: source => $auth_key
#   So it should be something like:
#   puppet:///modules/example42/openvpn/mykey
#   Can be also an array
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
# [*push*]
#   Push parameter
#
# [*template*]
#   Template to be used for the tunnel configuration.
#   Default is openvpn/server.conf.erb
#   File: openvpn/templates/server.conf.erb
#
# [*enable*]
#   If the tunnel is enabled or not.
#
# [*clients*]
#   The clients to allow and their configuration
#
# [*client_definedtype*]
#   The Defined Resource Type to invoke when configuring a client
#
# [*easyrsa_country*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_province*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_city*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_org*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_email*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_name*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_ou*]
#   Option for easy-rsa to generate the certificate with
#
# [*easyrsa_key_size*]
#   Option for easy-rsa to generate the certificate with
#
# == Examples
#
#  openvpn::tunnel { 'main':
#    dev              => 'tap',
#    server           => '172.31.253.0 255.255.255.0',
#    easyrsa_email    => 'devops@organization',
#    clients => {
#      'node42.fqdn' => { pushReset => true }
#    }
#  }
#
#
define openvpn::tunnel (
  $auth_type           = 'tls-server',
  $mode                = 'server',
  $remote              = '',
  $port                = $openvpn::port,
  $auth_key            = '',
  $proto               = $openvpn::protocol,
  $dev                 = 'tun',
  $server              = '10.8.0.0 255.255.255.0',
  $route               = '',
  $push                = '',
  $template            = '',
  $enable              = true,
  $clients             = {},
  $client_definedtype  = $openvpn::client_definedtype,
  $easyrsa_country     = $openvpn::easyrsa_country,
  $easyrsa_province    = $openvpn::easyrsa_province,
  $easyrsa_city        = $openvpn::easyrsa_city,
  $easyrsa_org         = $openvpn::easyrsa_org,
  $easyrsa_email       = $openvpn::easyrsa_email,
  $easyrsa_name        = $openvpn::easyrsa_name,
  $easyrsa_ou          = $openvpn::easyrsa_ou,
  $easyrsa_key_size    = $openvpn::easyrsa_key_size,
) {

  include openvpn

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

  $real_template = $template ? {
    ''      => $mode ? {
      'server' => 'openvpn/server.conf.erb',
      'client' => 'openvpn/client.conf.erb',
    },
    default => $template,
  }

  if $easyrsa_key_size < 2048 {
    # Assuming a CA is generated with a lifetime of 3650 days, 4096 really
    # should be used. See also:
    # http://lists.debian.org/debian-devel-announce/2010/09/msg00003.html
    # http://danielpocock.com/rsa-key-sizes-2048-or-4096-bits
    # http://news.techworld.com/security/3214360/rsa-1024-bit-private-key-encryption-cracked/
    # Ask in ##security on Freenode (IRC)
    notify { "A key size of ${easyrsa_key_size} bits was specified for\n
              tunnel ${name}. You really should upgrade to 2048 bits, or even\n
              4096 bits. Oh well, just don't blame us if you're hacked.": }
  }

  file { "openvpn_${name}.conf":
    ensure  => $manage_file,
    path    => "${openvpn::config_dir}/${name}.conf",
    mode    => $openvpn::config_file_mode,
    owner   => $openvpn::config_file_owner,
    group   => $openvpn::config_file_group,
    require => Package['openvpn'],
    notify  => Service['openvpn'],
    content => template($real_template),
  }

  if $auth_key != '' {
    file { "openvpn_${name}.key":
      ensure  => $manage_file,
      path    => "${openvpn::config_dir}/${name}.key",
      mode    => '0600',
      owner   => $openvpn::process_user,
      group   => $openvpn::process_user,
      require => Package['openvpn'],
      notify  => Service['openvpn'],
      source  => $auth_key,
    }
  }

  if $mode == 'server' {
    
    file { "${openvpn::config_dir}/${name}":
      ensure => directory,
      mode    => $openvpn::config_file_mode,
      owner   => $openvpn::config_file_owner,
      group   => $openvpn::config_file_group,
      require => Package['openvpn'],
    }

    file { "${openvpn::config_dir}/${name}/ccd":
      ensure => directory,
      mode    => $openvpn::config_file_mode,
      owner   => $openvpn::config_file_owner,
      group   => $openvpn::config_file_group,
      purge   => true,
      recurse => true,
      require => File[ "${openvpn::config_dir}/${name}" ]
    }

    if $auth_type == "tls-server" {

      if ! defined(Package[$openvpn::easyrsa_package]) {
        package { $openvpn::easyrsa_package:
          ensure => installed
        }
      }

      file { "${openvpn::config_dir}/${name}/easy-rsa/vars":
        ensure  => present,
        content => template('openvpn/easyrsa.vars.erb'),
        require => Exec["openvpn-tunnel-setup-easyrsa-${name}"];
      }

      file {"${openvpn::config_dir}/${name}/easy-rsa/openssl.cnf":
        ensure => link,
        target => "/etc/openvpn/${name}/easy-rsa/openssl-1.0.0.cnf",
        require => Exec["openvpn-tunnel-setup-easyrsa-${name}"]
      }

      exec {
        "openvpn-tunnel-setup-easyrsa-${name}":
          command => "/bin/cp -r ${openvpn::easyrsa_dir} ${openvpn::config_dir}/${name}/easy-rsa && \
                      chmod 755 ${openvpn::config_dir}/${name}/easy-rsa",
          creates => "${openvpn::config_dir}/${name}/easy-rsa",
          notify  => Service['openvpn'],
          require => File["${openvpn::config_dir}/${name}"];

        "openvpn-tunnel-rsa-dh-${name}":
          command  => '. ./vars && ./clean-all && RANDFILE=.rnd ./build-dh',
          cwd      => "${openvpn::config_dir}/${name}/easy-rsa",
          creates  => "${openvpn::config_dir}/${name}/easy-rsa/keys/dh${easyrsa_key_size}.pem",
          provider => 'shell',
          timeout  => 0,
          notify   => Service['openvpn'],
          require  => File["${openvpn::config_dir}/${name}/easy-rsa/vars"];

        "openvpn-tunnel-rsa-ca-${name}":
          command  => '. ./vars && ./pkitool --initca',
          cwd      => "${openvpn::config_dir}/${name}/easy-rsa",
          creates  => [ "${openvpn::config_dir}/${name}/easy-rsa/keys/ca.key", 
                        "${openvpn::config_dir}/${name}/easy-rsa/keys/ca.crt" ],
          provider => 'shell',
          timeout  => 0,
          notify   => Service['openvpn'],
          require  => [ Exec["openvpn-tunnel-rsa-dh-${name}"],
                        File["${openvpn::config_dir}/${name}/easy-rsa/openssl.cnf"] ];

        "openvpn-tunnel-rsa-servercrt-${name}":
          command  => ". ./vars && ./pkitool --server ${::fqdn}",
          cwd      => "${openvpn::config_dir}/${name}/easy-rsa",
          creates  => "${openvpn::config_dir}/easy-rsa/keys/${::fqdn}.key",
          provider => 'shell',
          notify   => Service['openvpn'],
          require  => Exec["openvpn-tunnel-rsa-ca-${name}"];
      }

      file { "${openvpn::config_dir}/${name}/keys":
        ensure  => link,
        target  => "${openvpn::config_dir}/${name}/easy-rsa/keys",
        require => Exec["openvpn-tunnel-setup-easyrsa-${name}"];
      }

    }

    # The each is required to allow one CN to be used
    # with multiple tunnels.
    each($clients) |$commonname, $params| {
      create_resources(
        $client_definedtype,
        { "${name}-${commonname}" => $params },
        { cn  => $commonname, tunnelName => $name }
      )

    }
  }

# Automatic monitoring of port and service
  if $openvpn::bool_monitor == true {

    $target = $remote ? {
      ''      => $openvpn::monitor_target,
      default => $remote,
    }

    if $proto == 'tcp' {
      monitor::port { "openvpn_${name}_${proto}_${port}":
        enable      => $bool_enable,
        protocol    => $proto,
        port        => $port,
        target      => $target,
        checksource => 'local',
        tool        => $openvpn::monitor_tool,
      }
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
      source      => $openvpn::firewall_src,
      destination => $openvpn::firewall_dst,
      protocol    => $proto,
      port        => $port,
      action      => 'allow',
      direction   => 'input',
      enable      => $bool_enable,
    }
  }

}
