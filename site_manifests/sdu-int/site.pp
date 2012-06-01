import 'cobbler-node'

node /sduos-int-build/ inherits cobbler-node {
  notify { "Matched build": }

  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

}
