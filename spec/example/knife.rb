#
# Set defaults
#
# If debug is set print extra output
debug = ENV['DEBUG']
# Set user from the environment
user = ENV['OPSCODE_USER'] || ENV['USER']
# Set the .chef configuration path that we are loading in from
config_dir = File.expand_path(File.dirname(__FILE__))
select_name = ENV['CHEF_SERVER_ALIAS'] || ENV['CSA']
# Set the default key value
if not select_name.nil? and not select_name.empty?
  key = "#{config_dir}/#{user}.#{select_name}.pem"
else
  key = "#{config_dir}/#{user}.pem"
end
# Standard knife options
log_level :info
log_location STDOUT
cache_type 'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )

# Config to enforce consistent parse engine
require 'yaml'
YAML::ENGINE.yamler = 'syck' if RUBY_VERSION > '1.9'

#
# Process config
#
# Read in the server config file
server_file = File.new("#{File.dirname(__FILE__)}/select_list.rb")
if Hash.respond_to? "try_convert"
  server_list = Hash.try_convert(eval(server_file.read()))
else
  server_list = eval(server_file.read())
end
server_overrides_path = "#{File.dirname(__FILE__)}/select_list_overrides.rb"
if File.exists? server_overrides_path
  server_overrides_file = File.new(server_overrides_path)
  if Hash.respond_to? "try_convert"
    server_overrides = Hash.try_convert(eval(server_overrides_file.read()))
  else
    server_overrides = eval(server_overrides_file.read())
  end
  # Replace keys in the server list with the overrides
  # Make sure the hashes that are the values of our keys are merged
  server_list.merge!(server_overrides) {|hash_key, oldval, newval|
      if oldval.respond_to? "merge"
        oldval.merge newval
      else
        newval
      end
    }
end

# Find the requested server - server_list is now a hash with keys of all servers
chef_server = server_list[select_name]

if not chef_server.nil?
  # Set the possible variables from the server config info
  url = chef_server["url"] if not chef_server["url"].nil?
  # For Private Chef - we have many orgs with one key
  # https://<server>/organizations/<org>
  split_url = url.split("/")
  key_part=select_name
  if split_url.include? "organizations"
    puts "Private Chef key naming rules being used" if debug
    # It is a private chef server - use server instead of select_name for key
    # [0]=https:/[1]=/[2]=<server>/[3]=organizations/[4]=<org>
    key_part=split_url[2]
    key = "#{config_dir}/#{user}.#{key_part}.pem"
  end
  if not chef_server["user"].nil?
    user = chef_server["user"]
    # Update the default key value
    key = "#{config_dir}/#{user}.#{key_part}.pem"
  end
  key = chef_server["key"] if not chef_server["key"].nil?
  validation_user = chef_server["validation_user"] if not chef_server["validation_user"].nil?
  validation_key = chef_server["validation_key"] if not chef_server["validation_key"].nil?
end

# Dynamically derive our cookbook directory from where we are in the filesystem
base = Dir.pwd
begin
  cb_path = nil
  Dir.foreach(base) do |dir|
    if dir.eql? "cookbooks"
      cb_path = "#{base}/#{dir}"
      break
    end
  end
  base = File.dirname(base)
end while base != "/" and cb_path.nil?
if cb_path.nil?
  cb_path = "~/cookbooks"
end

#
# Set the dynamic values
#
# Set the chef server url
puts "Setting chef_server_url to #{url}" if debug
chef_server_url url if not url.nil? and not url.empty?
# Set the chef user name
puts "Setting node_name to #{user}" if debug
node_name user if not user.nil? and not user.empty?
# Set the chef server private key to use
puts "Setting client_key to #{key}" if debug
client_key key if not key.nil? and not key.empty?
# Set the chef server validation user name
puts "Setting validation_client_name to #{validation_user}" if debug
validation_client_name validation_user if not validation_user.nil? and not validation_user.empty?
# Set the chef server validation key to use
puts "Setting validation_key to #{validation_key}" if debug
validation_key validation_key if not validation_key.nil? and not validation_key.empty?
# Set the cookbook path
puts "Setting cookbook_path to #{cb_path}" if debug
cookbook_path cb_path if not cb_path.nil? and not cb_path.empty?

