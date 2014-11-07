#
# Cookbook Name:: bcpc_hadoop
# Recipe:: journalnode
#
# Copyright 2014, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'base64'
include_recipe 'dpkg_autostart'
include_recipe 'bcpc_hadoop::hadoop_config'

%w{hadoop-hdfs-namenode }.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

if get_config("namenode_txn_fmt") then
  file "#{Chef::Config[:file_cache_path]}/nn_fmt.tgz" do
    user "hdfs"
    group "hdfs"
    user 0644
    content Base64.decode64(get_config("namenode_txn_fmt"))
    not_if { node[:bcpc][:hadoop][:mounts].all? { |d| File.exists?("/disk/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") } }
  end
end

node[:bcpc][:hadoop][:mounts].each do |d|
  directory "/disk/#{d}/dfs/jn/" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end
  directory "/disk/#{d}/dfs/jn/#{node.chef_environment}" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end
  bash "unpack nn fmt image" do
    user "hdfs"
    code ["pushd /disk/#{d}/dfs/",
          "tar xzvf #{Chef::Config[:file_cache_path]}/nn_fmt.tgz",
          "popd"].join("\n")
    notifies :restart, "service[hadoop-hdfs-journalnode]"
    only_if { not get_config("namenode_txn_fmt").nil? and not File.exists?("/disk/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") }
  end
end

link "/usr/lib/hadoop-hdfs/libexec" do
  to "/usr/lib/hadoop/libexec"
end

template "hadoop-hdfs-journalnode" do
  path "/etc/init.d/hadoop-hdfs-journalnode"
  source "hdp_hadoop-hdfs-journalnode.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, "service[hadoop-hdfs-journalnode]"
end

service "hadoop-hdfs-journalnode" do
  action [:start, :enable]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
end
