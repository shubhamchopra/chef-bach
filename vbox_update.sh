#!/bin/bash
vagrant ssh -c "rsync -avP --exclude vbox --exclude .chef /chef-bach-host/ /home/vagrant/chef-bach/"
vagrant ssh -c "cd chef-bach && knife environment from file environments/*.json && knife role from file roles/*.json && knife role from file roles/*.rb && knife cookbook upload -a -o cookbooks"
