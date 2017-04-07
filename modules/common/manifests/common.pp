# Class: common::common
#
# This class deploys basic requirements for node.

class common::common (
) {

  # $hosts = hiera_hash('::common::hosts', {
  #   "${::fqdn} ${::hostname}"              => '127.0.1.1',
  #   'localhost'                            => '127.0.0.1',
  #   'localhost ip6-localhost ip6-loopback' => '::1',
  #   'ip6-allnodes'                         => 'ff02::1',
  #   'ip6-allrouters'                       => 'ff02::2',
  # })

  # class { '::ntp' :}
  class { '::puppet::agent' :}

  class { '::system' :}

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

  # file { '/etc/hosts' :
  #   ensure  => 'present',
  #   owner   => 'root',
  #   group   => 'root',
  #   mode    => '0644',
  #   content => template('common/hosts.erb'),
  # }

  exec { '/bin/hostname -F /etc/hostname' :
    subscribe   => File['/etc/hostname'],
    refreshonly => true,
    require     => File['/etc/hostname'],
  }

}
