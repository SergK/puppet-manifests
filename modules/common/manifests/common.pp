# Class: common::common
#
# This class deploys basic requirements for node.

class common::common (
) {

  class { '::ntp' :}

  ensure_packages([
    'screen',
    'tmux',
  ], { ensure  => latest })

  case $::osfamily {
    'Debian': {
      include ::apt
      Apt::Source <| |> -> Package <| |>
    }
    'RedHat': {
      include ::yum
      include ::yum::repos
      $yum_repos_gpgkey = hiera_hash('yum::gpgkey', {})
      create_resources('::yum::gpgkey', $yum_repos_gpgkey)
      $yum_versionlock = hiera_hash('yum::versionlock', {})
      create_resources('::yum::versionlock', $yum_versionlock)
      Yum::Gpgkey <| |> -> Package <| tag !='yum-plugin' |>
      Yumrepo <| |> -> Package <| |>
    }
    default: { }
  }

  file { '/etc/hostname' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "${::fqdn}\n",
    notify  => Exec['/bin/hostname -F /etc/hostname'],
  }

  exec { '/bin/hostname -F /etc/hostname' :
    subscribe   => File['/etc/hostname'],
    refreshonly => true,
    require     => File['/etc/hostname'],
  }

}
