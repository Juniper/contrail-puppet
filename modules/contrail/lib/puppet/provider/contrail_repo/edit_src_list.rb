require 'tempfile'
require 'fileutils'
Puppet::Type.type(:contrail_repo).provide(:edit_src_list) do
  confine :osfamily => :debian
  defaultfor :osfamily => :debian
  commands :sed => 'sed', :head => 'head', :grep=> 'grep', :apt_get => 'apt-get'


  def exists?
    begin
      #puts @resource
      #print @resource[:repo_host]
      @property_hash[:ensure] == :present
      #grep_line= "\'deb http://" + @resource.value(:repo_host) + "/contrail/repo/" + @resource.value(:name) + " contrail main\'"
      #grep('-q', grep_line, '/root/sources.list')
      #rescue Puppet::ExecutionFailure => e
      #false
    end
  end

  def create
    path = '/etc/apt/sources.list'
    temp_file = Tempfile.new('foo')
    new_line= "deb http://" + resource[:repo_host] + "/contrail/repo/" + resource[:name] + " contrail main"
    
    temp_file.puts new_line
    begin
      File.open(path, 'r') do |file|
        file.each_line do |line|
          temp_file.puts line
        end
      end
      temp_file.close
      FileUtils.mv(temp_file.path, path)
      apt_get('update')
    ensure
      temp_file.close
      temp_file.unlink
    end
  end
  def self.instances
    path = '/etc/apt/sources.list'
    rules = []
    begin
      f = File.open(path, 'r')
      line_count = 0
      f.each_line do |line|
        line.chomp!
        next if line.empty?
        next if line.start_with? '#'
        line_array=line.split("/")
        line_count = line_count + 1
        #puts line
        if line_array[3] =='contrail' and line_array[4] == 'repo'
          source_list = {}
          repo_name= line_array[5].split().first
          repo_host = line_array[2]
          source_list[:name]=repo_name 
          source_list[:ensure]=:present
          source_list[:repo_host]=repo_host
          #puts source_list
          rules << new(source_list)
        #print rules
        #puts ""
        else
          ## contrail entries should only at the start
          #puts line_count
          break
        end
      end
      f.close
      #print source_list
      #puts ""
      #source_list.map do |name|
      #require 'ruby-debug'; debugger
      #source_list.each { |key, repo_host|
        #puts key, repo_host
        #rules << new( :name => key,
          #:ensure => :present,
          #:repo_host =>  repo_host
        #)
        #print rules
        #puts ""
      #}
    end
    #puts rules
    rules
  end


  def self.prefetch(resources)
    repos = instances
    resources.keys.each do | name|
      if provider = repos.find{ |repo| repo.name == name}
        resources[name].provider = provider
      end
    end
  end

end
