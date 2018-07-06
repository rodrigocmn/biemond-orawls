class nodemanager_service (

) {

  if $::operatingsystem == 'OracleLinux' {
    if versioncmp($::operatingsystemrelease, '7.0') < 0 {
      $init_style = 'sysv_redhat'
    } else {
      $init_style  = 'systemd'
    }
  } else {
    $init_style = undef
  }

  case $init_style {
    'systemd' : {
      file { "/etc/systemd/system/nodemanager_${name}.service":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('orawls/nodemanagersystemd.erb'),
        #notify  => Class['orawls::systemd'],
      }
      -> exec { '/bin/systemctl daemon-reload':
        refreshonly => true,
      }
      -> service { "nodemanager_${name}":
        ensure  => running,
        enable  => true,
      }

    }
    'sysv_redhat' : {
      file { "/etc/init.d/nodemanager_${name}.service":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('orawls/nodemanagersystemd.erb'),
        #notify  => Class['orawls::systemd'],
      }
      -> exec { '/sbin/chkconfig nodemanager_${name}':
        refreshonly => true,
      }
    }
    default: {
      fail("Init style not defined or not supported.")
    }

  }
}