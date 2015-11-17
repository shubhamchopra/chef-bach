#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive
# Description : To install hive/hcatalog core packages

include_recipe "bcpc-hadoop::hive_config"
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

# workaround for hcatalog dpkg not creating the hcat user it requires
user "hcat" do
  username "hcat"
  system true
  shell "/bin/bash"
  home "/usr/lib/hcatalog"
  supports :manage_home => false
  not_if { user_exists? "hcat" }
end

%w{hive hcatalog}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :upgrade
  end
end

#template "hive-config" do
#  path "/usr/lib/hive/bin/hive-config.sh"
#  source "hv_hive-config.sh.erb"
#  owner "root"
#  group "root"
#  mode "0755"
#end

bash "create-hive-warehouse" do
  code "hadoop fs -mkdir -p /user/hive/warehouse && hadoop fs -chmod 1777 /user/hive/warehouse && hadoop fs -chown hive /user/hive"
  user "hdfs"
end

bash "create-beeline-scratchroot" do
  code "hadoop fs -mkdir -p /tmp/hive-hive && hadoop fs -chmod 1777 /tmp/hive-hive && hadoop fs -chown hive /tmp/hive-hive"
  user "hdfs"
end
