#!/bin/bash

# bash imports
source ./virtualbox_env.sh

for i in `seq 1 3`; do
  $VBM controlvm bach-vm$i poweroff
  $VBM snapshot bach-vm$i restore initial-install
  vagrant ssh -c "cd chef-bach && knife client delete -y bach-vm$i.local.lan" || true
  vagrant ssh -c "cd chef-bach && knife node delete -y bach-vm$i.local.lan" || true
  $VBM startvm bach-vm$i
done
