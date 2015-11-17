include_recipe 'bcpc-hadoop::hbase_config'

node.default['bcpc']['hadoop']['copylog']['region_server'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.log", 
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['region_server_out'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.out", 
    'docopy' => true
}

%w{hbase-regionserver libsnappy1 phoenix}.each do |pkg|
  package pkg do
    action :upgrade
  end
end
%w{hbase-client hbase-regionserver phoenix-client}.each do |pkg|
  bash "hdp-select #{pkg}" do
    code "hdp-select set #{pkg} #{node[:bcpc][:hadoop][:distribution][:release]}"
    subscribes :run, "package[#{pkg}]", :immediate
    action :nothing
  end
end

user_ulimit "hbase" do
  filehandle_limit 32769
end

directory "/usr/hdp/current/hbase-regionserver/lib/native/Linux-amd64-64" do
  recursive true
  action :create
end

link "/usr/hdp/current/hbase-regionserver/lib/native/Linux-amd64-64/libsnappy.so" do
  to "/usr/lib/libsnappy.so.1"
end

template "/etc/default/hbase" do
  source "hdp_hbase.default.erb"
  mode 0655
  variables(:hbrs_jmx_port => node[:bcpc][:hadoop][:hbase_rs][:jmx][:port])
end

template "/etc/init.d/hbase-regionserver" do
  source "hdp_hbase-regionserver-initd.erb"
  mode 0655
end

service "hbase-regionserver" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "user_ulimit[hbase]", :delayed
  subscribes :restart, "bash[hdp-select hbase-regionserver]", :delayed
end
