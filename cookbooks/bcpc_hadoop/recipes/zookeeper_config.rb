#
# Cookbook Name:: bcpc_hadoop
# Recipe:: zookeeper_config
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

#
# Set up zookeeper configs
#
directory "/etc/zookeeper/conf.#{node.chef_environment}" do
  owner node[:bcpc][:hadoop][:zookeeper][:owner] 
  group node[:bcpc][:hadoop][:zookeeper][:group] 
  mode 00755
  action :create
  recursive true
end

bash "update-zookeeper-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/zookeeper/conf zookeeper-conf /etc/zookeeper/conf.#{node.chef_environment} 50
    update-alternatives --set zookeeper-conf /etc/zookeeper/conf.#{node.chef_environment}
  }
  not_if "update-alternatives --query zookeeper-conf | grep #{node.chef_environment}"
end

%w{zoo.cfg
  log4j.properties
  configuration.xsl
}.each do |t|
  template "/etc/zookeeper/conf/#{t}" do
    source "zk_#{t}.erb"
    mode 0644
    variables(:zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers])
  end
end
