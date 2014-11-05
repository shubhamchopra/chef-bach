
%w{hadoop-yarn-nodemanager
  hadoop-mapreduce}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# Install YARN Bits
template "/etc/hadoop/conf/container-executor.cfg" do
  source "hdp_container-executor.cfg.erb"
  owner "root"
  group "yarn"
  mode "0400"
  variables(:mounts => node[:bcpc][:hadoop][:mounts])
  action :create
  notifies :run, "bash[verify-container-executor]", :immediate
end

bash "verify-container-executor" do
  code "/usr/lib/hadoop-yarn/bin/container-executor --checksetup"
  group "yarn"
  action :nothing
  only_if { File.exists?("/usr/lib/hadoop-yarn/bin/container-executor") }
end

# Build nodes for YARN log storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/yarn/" do
    owner "yarn"
    group "yarn"
    mode 0755
    action :create
  end
  %w{mapred-local local logs}.each do |d|
    directory "/disk/#{i}/yarn/#{d}" do
      owner "yarn"
      group "hadoop"
      mode 0755
      action :create
    end
  end
end

link "/usr/lib/hadoop/lib/native/libgplcompression.la" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.la"
end

link "/usr/lib/hadoop/lib/native/libgplcompression.a" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.a"
end

link "/usr/lib/hadoop/lib/native/libgplcompression.so.0.0.0" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.so.0.0.0"
end

yarn_dep = ["template[/etc/hadoop/conf/hadoop-env.sh]", "template[/etc/hadoop/conf/yarn-site.xml]"]

hadoop_service "hadoop-yarn-nodemanager" do
  dependencies yarn_dep
  process_identifier "org.apache.hadoop.yarn.server.nodemanager.NodeManager"
end
