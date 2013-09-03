# vim: ts=2:sw=2:expandtab:
#
# Knife plugin for selecting chef server to interact with
#
# Environment variable based chef server selection
#
# (C) Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Author: Jon-Paul Sullivan <jonpaul.sullivan@hp.com>
#

module HPCS

  SELECT_LIST = "#{::Chef::Knife::chef_config_dir}/select_list.rb"
  SELECT_OVERRIDES = "#{::Chef::Knife::chef_config_dir}/select_list_overrides.rb"
  SELECTED = ENV['CHEF_SERVER_ALIAS']

  def read_select_list
    # Read the server list from the server file
    if Hash.respond_to? "try_convert"
      server_list = Hash[Hash.try_convert(eval(File.new(SELECT_LIST).read())).sort]
    else
      server_list = Hash[(eval(File.new(SELECT_LIST).read())).sort]
    end
    server_overrides = Hash.new
    if File.exists? SELECT_OVERRIDES
      if Hash.respond_to? "try_convert"
        server_overrides = Hash[Hash.try_convert(eval(File.new(SELECT_OVERRIDES).read()))]
      else
        server_overrides = Hash[eval(File.new(SELECT_OVERRIDES).read())]
      end
      # Replace keys in the server list with the overrides
      server_list.merge! server_overrides
    end
    server_list
  end
  module_function :read_select_list

  class Select < ::Chef::Knife
    banner "knife select (options) [CHEF_SERVER_ALIAS]"

    option :full,
      :short => "-f",
      :long  => "--full",
      :boolean => true,
      :description => "Show full chef server information"

    def run
      if name_args.size != 1
        # Print the list of known aliases
        list = HPCS::SelectList.new
        list.config[:full] = config[:full]
        list.config[:format] = config[:format]
        if name_args.size != 0
          ui.error "Please choose from the following list of chef server aliases:"
          ret_val = 1
        else
          ret_val = 0
        end
        list.run
        exit ret_val
      end

      # We've been given an alias to use
      use_alias = name_args.first
      # Read in the list of all of the servers
      alias_list = HPCS::read_select_list
      # Check that the alias is known
      if alias_list.has_key? use_alias
        # Print the export command that will set the environment variable
        ui.msg "export CHEF_SERVER_ALIAS=#{use_alias}"
      else
        # Expectation is that this is eval'ed in the shell - so be nice and echo
        ui.msg "echo \"No such alias: #{use_alias}\""
      end
    end
  end

  class SelectList < ::Chef::Knife
    banner "knife select list (options)"

    option :full,
      :short => "-f",
      :long  => "--full",
      :boolean => true,
      :description => "Show full chef server information"

    def run
      # Read in the list of all of the servers
      alias_list = HPCS::read_select_list
      if not SELECTED.nil? and not SELECTED.empty?
        ui.msg "Currently selected server is #{SELECTED}"
        if not alias_list.has_key? SELECTED
          ui.warn "Chosen server not found in server list"
        end
      end
      if config[:full]
        ui.output alias_list
      else
        ui.output alias_list.keys
      end
    end
  end

  class SelectNew < ::Chef::Knife
    banner "knife select new CHEF_SERVER_ALIAS (options)"

    option :user,
      :short => "-u",
      :long  => "--user USER",
      :default => "",
      :description => "Set the user name for the chef server alias"

    option :server_url,
      :short => "-s",
      :long  => "--server-url",
      :default => "",
      :description => "Set the server url for the chef server alias"

    option :key,
      :short => "-k",
      :long  => "--key",
      :default => "",
      :description => "Set the user private key file for the chef server alias"

    deps do
      require 'tempfile'
      require 'pp'
    end

    def run
      if name_args.size != 1
        ui.fatal "You must specifiy the name of the alias to add"
      end
      new_alias = name_args.first
      alias_hash = Hash.new
      # Check that the alias doesn't already exist
      alias_list = HPCS::read_select_list
      if alias_list.has_key? new_alias
        ui.confirm "The alias #{new_alias} already exists, replace it?"
      end
      # Retrieve all the information that we need
      if config[:user].nil? or config[:user].empty?
        default_user = ENV['OPSCODE_USER'] || ENV['USER']
        config[:user] = ui.ask_question "Username?", {:default => default_user}
        alias_hash["user"] = config[:user]
      end
      if config[:server_url].nil? or config[:server_url].empty?
        default_server = "http://#{new_alias}:4000"
        config[:server_url] = ui.ask_question "URL?", {:default => default_server}
        alias_hash["server_url"] = config[:server_url]
      end
      if config[:key].nil? or config[:key].empty?
        default_key = "#{::Chef::Knife::chef_config_dir}/#{config[:user]}.#{new_alias}.pem"
        config[:key] = ui.ask_question "Key filename?", {:default => default_key}
        alias_hash["key"] = config[:key]
      end
      if config[:validation_user].nil? or config[:validation_user].empty?
        default_validation_user = "#{new_alias}-validator"
        config[:validation_user] = ui.ask_question "Validation User?",
                      {:default => default_validation_user}
        alias_hash["validation_user"] = config[:validation_user]
      end
      if config[:validation_key].nil? or config[:validation_key].empty?
        default_validation_key =
                  "#{::Chef::Knife::chef_config_dir}/#{new_alias}-validator.pem"
        config[:validation_key] = ui.ask_question "Validation Key filename?",
                      {:default => default_validation_key}
        alias_hash["validation_key"] = config[:validation_key]
      end
      # Add the alias to the list
      alias_list[new_alias] = alias_hash
      # Write it out to file
      begin
        select_file = File.new(SELECT_LIST)
        select_file.flock(File::LOCK_EX)
        tmp_file = Tempfile.new("#{File.basename(SELECT_LIST)}",
                    "#{File.dirname(SELECT_LIST)}")
        PP::pp alias_list, tmp_file
        tmp_file.flush
        tmp_file.close
        FileUtils.cp tmp_file, select_file
      rescue Exception => e
        ui.error "Error adding #{new_alias} to #{select_file}"
        raise e
      ensure
        select_file.flock(File::LOCK_UN)
        select_file.close
        tmp_file.close
        tmp_file.unlink
      end
    end
  end
end
