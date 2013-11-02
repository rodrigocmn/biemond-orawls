# == Class: orawls::weblogic
#
class orawls::weblogic (
  $version              = undef, # 1036|1211|1212
  $filename             = undef, # wls1036_generic.jar|wls1211_generic.jar|wls_121200.jar
  $jdk_home_dir         = undef, # /usr/java/jdk1.7.0_45
  $oracle_base_home_dir = undef, # /opt/oracle
  $middleware_home_dir  = undef, # /opt/oracle/middleware11gR1
  $os_user              = undef, # oracle
  $os_group             = undef, # dba
  $download_dir         = undef, # /data/install
  $source               = undef, # puppet:///modules/orawls/ | /mnt | /vagrant
  $log_output           = false, # true|false
  ) {

  if ($version == 1036 or $version == 1211) {
    $silent_template = "orawls/weblogic_silent_instal.xml.erb"
  } elsif ( $version == 1212) {
    $silent_template = "orawls/weblogic_silent_install_1212.xml.erb"
  } else  {
    fail('unknown weblogic version parameter')
  }

  $exec_path         = "${jdk_home_dir}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
  $ora_inventory_dir = "${oracle_base_home_dir}/oraInventory"

  Exec {
    logoutput => $log_output,
  }

  # check if the middleware already exists
  $found = wls_exists($middleware_home_dir)

  if $found == undef {
    $continue = true
  } else {
    if ($found) {
      $continue = false
    } else {
      notify { "orawls::weblogic version ${version} ${middleware_home_dir} does not exists": }
      $continue = true
    }
  }

  if ($continue) {
    if $source == undef {
      $mountPoint = "puppet:///modules/orawls/"
    } else {
      $mountPoint = $source
    }

    orawls::utils::structure{'weblogic structure ${version}':
      oracle_base_home_dir => $oracle_base_home_dir,
      ora_inventory_dir    => $ora_inventory_dir,
      os_user              => $os_user,
      os_group             => $os_group,
      download_dir         => $download_dir,
      log_output           => $log_output,
    }

    # put weblogic generic jar
    file { "${download_dir}/${filename}":
      source  => "${mountPoint}/${filename}",
      ensure  => file,
      replace => false,
      backup  => false,
      mode    => 0775,
      owner   => $os_user,
      group   => $os_group,
      require => Orawls::Utils::Structure['weblogic structure ${version}'],
    }

    # de xml used by the wls installer
    file { "${download_dir}/weblogic_silent_install.xml":
      content => template($silent_template),
      ensure  => present,
      replace => 'yes',
      mode    => 0775,
      owner   => $os_user,
      group   => $os_group,
      require => Orawls::Utils::Structure['weblogic structure ${version}'],
    }

    if ($version == 1212) {
      # only necessary for WebLogic >= 1212
      orawls::utils::orainst{'weblogic orainst ${version}':
        ora_inventory_dir => $ora_inventory_dir,
        os_group          => $os_group,
      }

      $command = "-silent -responseFile ${download_dir}/weblogic_silent_install.xml "
      exec { "install weblogic ${version}":
        command     => "java -jar ${download_dir}/${filename} ${command} -invPtrLoc /etc/oraInst.loc -ignoreSysPrereqs",
        environment => ["JAVA_VENDOR=Sun", "JAVA_HOME=${jdk_home_dir}"],
        timeout     => 0,
        path        => $exec_path,
        user        => $os_user,
        group       => $os_group,
        require     => [Orawls::Utils::Structure['weblogic structure ${version}'],
                        Orawls::Utils::Orainst['weblogic orainst ${version}'],
                        File["${download_dir}/${filename}"],
                        File["${download_dir}/weblogic_silent_install.xml"]],
      }
    } else {

      $javaCommand = "java -Xmx1024m -jar"
      exec {"install weblogic ${version}":
        command     => "${javaCommand} ${download_dir}/${filename} -mode=silent -silent_xml=${download_dir}/weblogic_silent_install.xml",
        environment => ["JAVA_VENDOR=Sun","JAVA_HOME=${jdk_home_dir}"],
        path        => $exec_path,
        user        => $os_user,
        group       => $os_group,
        require     => [Orawls::Utils::Structure['weblogic structure ${version}'],
                        File["${download_dir}/${filename}"],
                        File["${download_dir}/weblogic_silent_install.xml"]],
      }
    }
  }
}