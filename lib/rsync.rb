=begin rdoc
 This class exists for two reasons: (1) as a wrapper around the rsync command but (2) more importantly that it allows
 us to easily do one-way or two-way synchs. But actually, the class is poorly written and doesn't reflect this well.
   It needs to be rewritten. Sorry. 
=end
class RsyncCmd
  def initialize(*args)
    opts = {:ssh => 'ssh',
            :rsync => 'rsync',
            :sshuser => '',
            :sshserver => '',
            :sshport => '',
            :privatekey => '',
            :src => '',
            :dest => '',
            :verbose => '-v',
            :dryrun => false,
            :rsynopts => '-a -u',
            :excludefile => 'IGNORE'
            }  
    args.each { |arg| opts.merge!(arg) unless !arg.kind_of?(Hash) }
    opts.each { |k, v| self.instance_variable_set("@#{k.to_s}", v) }
    @opts = opts
  end
  
  protected
  def ssh
    @privatekey.empty? && @sshport.empty? ? '' : "-e 'ssh #{ssh_port} #{public_key_authentication}'"
  end
  
  def ssh_port
    @sshport.empty? ? '' : "-p #{@sshport}"
  end
  
  def public_key_authentication
    @privatekey.empty? ? '' : "-i #{@privatekey}"
  end
  
  def server(push=true)
    push ? server_push : server_pull
  end
  
  def server_push
    @sshserver.empty? ? "#{@src} #{@dest}" : "#{@src} #{@sshuser}@#{@sshserver}:#{@dest}"    
  end

  def server_pull
    @sshserver.empty? ? "#{@src} #{@dest}" : "#{@sshuser}@#{@sshserver}:#{@src} #{@dest}"    
  end
  
  def dry_run
    return @dryrun ? "--dry-run" : ''
  end
  
  def excludes
    @excludefile.empty? ? '' : "--exclude-from=#{@excludefile}"
  end
  
  public
  def to_s(push=true)
    "#{@rsync} #{@verbose} #{dry_run} #{ssh} #{excludes} #{@rsynopts} #{server push}"
  end
  
  def default_backup_remote_opts
    "--force --delete-excluded -a"
#    "--force --ignore-errors --delete-excluded  --backup --backup-dir=#{@dest} -a"
  end
  
  def build from, to, dryrun=true, push=true
    @src = from
    @dest = to
    @dryrun = dryrun
    to_s push
  end
  alias push build #alias push so that push and pull come in a pair
  
  def pull from, to, dryrun=true, push=false
    build from, to, dryrun, push
  end
  
end