require 'rubygems'
require 'pathname'
require 'lib/userlogger'
require 'lib/command'
require 'lib/rsync'
require 'ostruct'

CONFIG = OpenStruct.new(
  :opts => []
)

class SyncFolders
  attr_reader :sync, :backup,:opts 
  attr_accessor :dryrun, :cmd
  
  def initialize(*args)
    opts = {:base => [],
            :backup => [],
            :sync => [],
            :dryrun => true,
            :cmd => RsyncCmd.new,
            :logger => nil
            }  
    args.each { |arg| opts.merge!(arg) unless !arg.kind_of?(Hash) }
    @opts = opts
    opts.each { |k, v| self.instance_variable_set("@#{k.to_s}", v) }
  end
  
  protected
  def to
    Pathname.new(@base[1])
  end
  
  def from
    Pathname.new(@base[0])    
  end
  
  def cmd (cmd)
    c = UserCommand.new(cmd)
    m = Command.new(c)

    if !@logger.nil?  
      logger = @logger
      logger.start
      logger.run { m.emit }
      logger.stop    
    else
      puts "******* #{cmd}  ***********"
      m.emit
    end
    
  end
      
  def sync
    @sync.each do |folder|  
      cmd  @cmd.send(:push, from + folder, to, @dryrun)
      cmd  @cmd.send(:pull, to + folder, from, @dryrun)
    end    
  end
  
  def backup
    @backup.each do |folder|  
      cmd  @cmd.send(:push, from + folder, to, @dryrun)
    end    
  end
  
  def dryrun
    dryrun = @dryrun
    @dryrun = true
    run :sync, :backup
    @dryrun = dryrun
  end
  
  public
  def all
    @dryrun = false
    run :sync, :backup
    @dryrun = true
  end
  
  def run (*targets)
    targets.each { |target| self.send(target) } unless targets.nil?
  end
end