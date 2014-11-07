#
# Cookbook Name:: bcpc_hadoop
# Recipe:: configs
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

# ensure we use /etc/security/limits.d to allow ulimit overriding
if not node.has_key?('pam_d') or not node['pam_d'].has_key?('services') or not node['pam_d']['services'].has_key?('common-session')
  node.default['pam_d']['services'] = {
    'common-session' => {
      'main' => {
        'pam_permit_default' => {
          'interface' => 'session', 'control_flag' => '[default=1]', 'name' => 'pam_permit.so' },
        'pam_deny' => {
          'interface' => 'session', 'control_flag' => 'requisite', 'name' => 'pam_deny.so' },
        'pam_permit_required' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_permit.so' },
        'pam_limits' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_limits.so' },
        'pam_umask' => {
          'interface' => 'session', 'control_flag' => 'optional', 'name' => 'pam_umask.so' },
        'pam_unix' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_unix.so' }
      },
      'includes' => []
    }
  }
   
end

# set vm.swapiness to 0 (to lessen swapping)
include_recipe 'sysctl::default'
sysctl_param 'vm.swappiness' do
  value 0
end

# Populate node attributes for all kind of hosts
set_hosts

package "bigtop-jsvc"

template "hadoop-detect-javahome" do
  path "/usr/lib/bigtop-utils/bigtop-detect-javahome"
  source "hdp_bigtop-detect-javahome.erb"
  owner "root"
  group "root"
  mode "0755"
end

%w{openjdk-7-jdk zookeeper}.each do |pkg|
  package pkg do
    action :upgrade
  end
end
