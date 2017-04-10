#!/bin/bash

set -xe

export DEBIAN_FRONTEND="noninteractive"
export PUPPET_ETC_DIR="/etc/puppetlabs/"
export HIERA_VAR_DIR="/var/lib/hiera"

# check if running it as root
if [[ "$(id -u)" != "0" ]]; then
  echo "Error. This script must be run as root"
  exit 1
fi

# check if puppet etc dir exists
if [[ ! -d "${PUPPET_ETC_DIR}" ]]; then
  echo "Error. Could not find Puppet etc directory!"
  exit 1
fi

EXPECT_HIERA="$(puppet apply -vd --genconfig | awk '/ hiera_config / {print $3}')"
echo "Populating hiera config"
cp -v ${HIERA_VAR_DIR}/hiera-stub.yaml "${EXPECT_HIERA}"

/opt/puppetlabs/puppet/bin/gem install deep_merge --no-rdoc --no-ri

# FIXME(skulanov): Replace by puppet-librarian
PUPPET_MODULES="\
  camptocamp-puppetserver \
  puppetlabs-apt \
  puppetlabs-concat \
  puppetlabs-ntp \
  puppetlabs-stdlib \
  thias-sysctl \
  "

for module in ${PUPPET_MODULES}; do
  puppet module install "${module}"
done

echo FACTER_PUPPET_APPLY="true" FACTER_ROLE="puppetmaster" \
  puppet apply -vd --detailed-exitcodes ${PUPPET_ETC_DIR}/code/environments/production/manifests/site.pp

echo puppet agent --enable
echo puppet agent -vd --no-daemonize --onetime
