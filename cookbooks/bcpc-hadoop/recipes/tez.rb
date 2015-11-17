#
# Cookbook Name : bcpc-hadoop
# Recipe Name : TEZ
# Description : To setup TEZ
#
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

package hwx_pkg_str('tez', node[:bcpc][:hadoop][:distribution][:release]) do
  action :upgrade
end

directory "/etc/tez/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-tez-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/tez/conf tez-conf /etc/tez/conf.#{node.chef_environment} 50
    update-alternatives --set tez-conf /etc/tez/conf.#{node.chef_environment}
  }
end

template "/etc/tez/conf/tez-site.xml" do
  source "hdp_tez-site.xml.erb"
  mode 0655
end

bash "make_apps_tez_dir" do
  code <<EOH
  hdfs dfs -mkdir -p /apps/tez
EOH
  user "hdfs"
  not_if "hdfs dfs -test -d /apps/tez/", :user => "hdfs"
end

bash "make_dir_to_copy_tez_targz" do
  code <<EOH
  hdfs dfs -mkdir -p /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/tez/ 
  hdfs dfs -put /usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/tez/lib/tez.tar.gz /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/tez/
  hdfs dfs -chown -R hdfs:hadoop /hdp
  hdfs dfs -chmod -R 555 /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/tez
  hdfs dfs -chmod -R 444 /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/tez/tez.tar.gz
EOH
  user "hdfs"
  not_if "hdfs dfs -test -f /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/tez/tez.tar.gz", :user => "hdfs"
  only_if "echo 'test'|sudo -u hdfs hdfs dfs -copyFromLocal - /tmp/tez-test"
  notifies :run,"bash[delete-tez-temp-file]",:immediately
end

bash "delete-tez-temp-file" do
  code <<-EOH
  hdfs dfs -rm /tmp/tez-test
  EOH
  user "hdfs"
  action :nothing
end
