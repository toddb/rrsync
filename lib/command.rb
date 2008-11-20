# require 'FileUtils'
require 'open3'

# Design and code altered from TextMate bundles

class UserCommand
  attr_reader :display_name, :path
  def initialize(cmd)
    @cmd = cmd
  end
  def run
    stdin, stdout, stderr, pid = my_popen3(@cmd)
    return stdout, stderr, nil, pid
  end
  def to_s
    @cmd.to_s
  end
  
  protected
  def my_popen3(*cmd) # returns [stdin, stdout, strerr, pid]
    pw = IO::pipe   # pipe[0] for read, pipe[1] for write
    pr = IO::pipe
    pe = IO::pipe

    pid = fork{
      pw[1].close
      STDIN.reopen(pw[0])
      pw[0].close

      pr[0].close
      STDOUT.reopen(pr[1])
      pr[1].close

      pe[0].close
      STDERR.reopen(pe[1])
      pe[1].close

      exec(*cmd)
    }

    pw[0].close
    pr[1].close
    pe[1].close

    pw[1].sync = true

    [pw[1], pr[0], pe[0], pid]
  end
end

class Command
    def initialize (command)
      # the object `command` needs to implement a method `run`.  `run` should
      # return an array of three file descriptors [stdout, stderr, stack_dump].
      @error = ""
      @command = command
      STDOUT.sync = true
      @mate = self.class.name
    end
  protected
    def filter_stdout(str)
      # strings from stdout are passed through this method before being printed
      htmlize(str).gsub(/\<br\>/, "<br>\n")
    end
    def filter_stderr(str)
      # strings from stderr are passed through this method before printing
      "<span style='color: red'>#{htmlize str}</span>".gsub(/\<br\>/, "<br>\n")
    end
  public
    def emit_html
      stdout, stderr, stack_dump, @pid = @command.run
        %w[INT TERM].each do |signal|
          trap(signal) do
            begin
              Process.kill("KILL", @pid)
              sleep 0.5
              Process.kill("TERM", @pid)
            rescue
              # process doesn't exist anymore
            end
          end
        end
        TextMate::IO.exhaust(:out => stdout, :err => stderr, :stack => stack_dump) do |str, type|
          case type
            when :out   then print filter_stdout(str)
            when :err   then puts filter_stderr(str)
            when :stack then @error << str
          end
        end
        Process.waitpid(@pid)
      end 

      def emit
        stdout, stderr, stack_dump, @pid = @command.run
          %w[INT TERM].each do |signal|
            trap(signal) do
              begin
                Process.kill("KILL", @pid)
                sleep 0.5
                Process.kill("TERM", @pid)
              rescue
                # process doesn't exist anymore
              end
            end
          end
          TextMate::IO.exhaust(:out => stdout, :err => stderr, :stack => stack_dump) do |str, type|
            case type
              when :out   then print str
              when :err   then puts str
              when :stack then @error << str
            end
          end
          Process.waitpid(@pid)
        end 

end

module TextMate
  module IO
    
    @sync = false
    @blocksize = 4096
    
    class << self
    
      attr_accessor :sync
      def sync?; @sync end
      
      attr_accessor :blocksize

      def exhaust(named_fds, &block)
        
        leftovers = {}
        named_fds = named_fds.dup
        named_fds.delete_if { |key, value| value.nil? }
        named_fds.each_key {|k| leftovers[k] = "" }
        
        until named_fds.empty? do
          
          fd   = select(named_fds.values)[0][0]
          name = named_fds.find { |key, value| fd == value }.first
          data = fd.sysread(@blocksize) rescue ""
          
          if data.to_s.empty? then
            named_fds.delete(name)
            fd.close
          
          elsif not sync?
            if data =~ /\A(.*\n|)([^\n]*)\z/m
              if $1 == ""
                leftovers[name] += $2
                next
              end
              lines = leftovers[name].to_s + $1
              leftovers[name] = $2
              case block.arity
                when 1: lines.each { |line| block.call(line) }
                when 2: lines.each { |line| block.call(line, name) }
              end
            else
              raise "Allan's regexp did not match #{str}" 
            end
          
          elsif sync?
            case block.arity
              when 1: block.call(data)
              when 2: block.call(data, name)
            end
          
          end
        end
        
        # clean up the crumbs
        if not sync?
          leftovers.delete_if {|name,crumb| crumb == ""}
          case block.arity
            when 1: leftovers.each_pair { |name, crumb| block.call(crumb) }
            when 2: leftovers.each_pair { |name, crumb| block.call(crumb, name) }
          end
        end
        
      end
            
    end
    
  end
end
