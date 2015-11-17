
module Bcpc_Hadoop
  module Helper

    include Chef::Mixin::ShellOut

    # Verify an HDFS directory exists or create it
    #
    # hdfs - String HDFS URI (e.g. hdfs://FOO1)
    # path - String path of directory
    # owner - String of owner to own directory
    #
    # Raises RuntimeError on any unspecified error
    # Raises Mixlib::ShellOut::CommandTimeout on a hung command
    #
    def new_dir_creation(hdfs, path, user, perms, run_context)
      hdfs_dir_test = "sudo -u hdfs hdfs dfs -test -d #{hdfs}/#{path}"
      # Do not rescue Mixlib::ShellOut::CommandTimeout -- we should fail the run if HDFS is unavailable
      Chef::Log.info("Verifying HDFS dir #{path}")
      if Mixlib::ShellOut.new(hdfs_dir_test, :timeout=>90).run_command.exitstatus == 1
        Chef::Log.info("HDFS dir #{path} creation")
        hdfs_mkdir_cmds = "sudo -u hdfs hdfs dfs -mkdir #{hdfs}/#{path} && sudo -u hdfs hdfs dfs -chown #{user} #{hdfs}/#{path}"
        so = Mixlib::ShellOut.new(hdfs_mkdir_cmds, :timeout=>90)
        if so.run_command.exitstatus != 0
          raise "Unable to successfully run: #{hdfs_mkdir_cmds}\nReturn code #{so.stderr}; stderr: #{so.stderr}\n"
        end
      end
    end

    # Verify a Group Matches Business Rules
    #
    # group - String of group to verify
    # users - Array of users who are members of the group
    # prohibited_groups - Array of group reg. ex.'s to filter
    #
    # Returns - false if the group does not match business criteria
    #         - true  if the group does meet business criteria
    #
    def filter_nonproject_groups(group, users, prohibited_groups)
      # weed out groups which have fewer than two users
      return false if users.length < 2
      # weed out groups which failed name resolution (so we get the GID)
      return false if group.to_i.to_s == group

      prohibited_regexs = prohibited_groups.map{ |regex_str| Regexp.new(regex_str) }
      return !prohibited_regexs.map!{ |r| r.match(group) }.any?
    end
  end
end
