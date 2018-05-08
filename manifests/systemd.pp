class orawls::systemd {
  exec { '/bin/systemctl daemon-reload':
    refreshonly => true,
  }
}
