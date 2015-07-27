package "xfsprogs" do
  action :install
end

directory "/disk" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

if node[:bcpc][:hadoop][:disks].length > 0 then
  node[:bcpc][:hadoop][:disks].each_index do |i|
    directory "/disk/#{i}" do
      owner "root"
      group "root"
      mode 00755
      action :create
      recursive true
    end
   
    d = node[:bcpc][:hadoop][:disks][i]
    execute "mkfs -t xfs -f /dev/#{d}" do
      not_if "file -s /dev/#{d} | grep -q 'SGI XFS filesystem'"
    end
 
    mount "/disk/#{i}" do
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64,nobootwait"
      action :mount
      ignore_failure true
    end

    # disk should be mounted from above; if not, we can only assume its
    # filesystem needs help; however, xfs_repair does not give a "good"
    # (mountable) filesystem a clean bill of health in many cases so only
    # if we can not mount do we then assume the worst and truncate its log
    # and worse log truncation always seems to return non-zero too
    bash "/sbin/xfs_repair -L /dev/#{d}" do
      code "/sbin/xfs_repair -L /dev/#{d}"
      not_if "mount | grep -q '^/dev/#{d} '"
      returns [0,139]
    end

    mount "/disk/#{i} verify mount" do
      mount_point "/disk/#{i}"
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64,nobootwait"
      action [:mount,:enable]
    end

  end
  node.set[:bcpc][:hadoop][:mounts] = (0..node[:bcpc][:hadoop][:disks].length-1).to_a
else
  Chef::Application.fatal!('Please specify some node[:bcpc][:hadoop][:disks]!')
end
