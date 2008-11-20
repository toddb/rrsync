require 'Logger'
require 'benchmark'

class UserLogger

  def initialize(*args)
    opts = {:file => '/var/log/rrsync.log',
            :age => 'daily',
            :debug => true,    #If true output to screen else output is sent to log file.
            :silent => false   #Total silent = no log or screen output.
           }
    args.each do |arg|
        arg.each { |k,v| opts[k] = v  } unless !arg.kind_of?(Hash)
    end
  
    if opts[:debug] && !opts[:silent]
      logger = Logger.new(STDOUT,opts[:age])
    elsif opts[:file] != '' && !opts[:silent]
      logger = Logger.new(opts[:file], opts[:age])
    else
      logger = Logger.new(nil)
    end
    @logger = logger
  end

  def start
    @logger.info("Started running at: #{Time.now}") 
    @run_time = Time.now 
  end
  
  def stop
    @logger.info("Finished running at: #{Time.now} - Execution time: #{@run_time.to_s[0, 5]}")
  end
  
  def run &block
    @run_time = Benchmark.realtime do
      begin
        yield unless !block_given?
      rescue Errno::EACCES, Errno::ENOENT, Errno::ENOTEMPTY, Exception => e
        @logger.fatal(e.to_s)
      end
    end
  end
   
end
