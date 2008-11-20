
local = {
    :base   => %w(~/Documents/ ~/Documents/backup/testing),
    :backup => %w(src home agile-2008),
    :sync   => %w(agile)
      }
      
remote = {
    :base   => %w(~/Documents/ ENV['RSYNC_SERVER_BASE']),
    :backup => %w(src home agile-2008),
    :sync   => %w(agile),
    :cmd    => RsyncCmd.new({
              :sshuser   =>  ENV['RSYNC_USER'],
              :sshserver =>  ENV['RSYNC_SSH_SERVER'],
              :privatekey => ENV['RSYNC_PRIVATE_KEY'],
              :rsynopts  =>  RsyncCmd.new().default_backup_remote_opts
              })
      }

CONFIG.opts << local << remote
