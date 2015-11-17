
include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::zookeeper_config'
dpkg_autostart "zookeeper-server" do
  allow false
end

package  "zookeeper-server" do
  action :upgrade
  notifies :create, "template[#{Chef::Config[:file_cache_path]}/zkServer.sh]", :immediately
  notifies :create, "ruby_block[Compare_zookeeper_server_start_shell_script]", :immediately
end

user_ulimit "zookeeper" do
  filehandle_limit 32769
end

template "#{Chef::Config[:file_cache_path]}/zkServer.sh" do
  source "zk_zkServer.sh.orig.erb"
  mode 0644
end

ruby_block "Compare_zookeeper_server_start_shell_script" do
  block do
    require "digest"
    orig_checksum=Digest::MD5.hexdigest(File.read("#{Chef::Config[:file_cache_path]}/zkServer.sh"))
    new_checksum=Digest::MD5.hexdigest(File.read("/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/zookeeper/bin/zkServer.sh"))
    if orig_checksum != new_checksum
      Chef::Application.fatal!("zookeeper-server:New version of zkServer.sh need to be created and used")
    end
  end
  action :nothing
end

template "/etc/init.d/zookeeper-server" do
  source "zk_zookeeper-server-initd.erb"
  mode 0655
end

directory "/var/run/zookeeper" do 
  owner "zookeeper"
  group "zookeeper"
  mode "0755"
  action :create
end

link "/usr/bin/zookeeper-server-initialize" do
  to "/usr/hdp/current/zookeeper-client/bin/zookeeper-server-initialize"
end

template "#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zookeeper-env.sh" do
  source "zk_zookeeper-env.sh.erb"
  mode 0644
  variables(:zk_jmx_port => node[:bcpc][:hadoop][:zookeeper][:jmx][:port])
end

directory node[:bcpc][:hadoop][:zookeeper][:data_dir] do
  recursive true
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0755
end

template "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/zookeeper/bin/zkServer.sh" do
  source "zk_zkServer.sh.erb"
end

bash "init-zookeeper" do
  code "service zookeeper-server init --myid=#{node[:bcpc][:node_number]}"
  not_if { ::File.exists?("#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid") }
end

file "#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid" do
  content node[:bcpc][:node_number]
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0644
end

service "zookeeper-server" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zoo.cfg]", :delayed
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zookeeper-env.sh]", :delayed
  subscribes :restart, "template[/usr/lib/zookeeper/bin/zkServer.sh]", :delayed
  subscribes :restart, "file[#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid]", :delayed
  subscribes :restart, "user_ulimit[zookeeper]", :delayed
end
