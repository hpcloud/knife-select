# vim: ts=2:sw=2:expandtab:
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

# Pre-requisites setup
require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.configure do |config|
  config.before(:all) do
    require 'pp'
    require 'tempfile'
    require 'json'

    # We need to be 1 level above the .chef directory we want to test with to make this work
    @local_dir = File.dirname(__FILE__)
    Dir.chdir @local_dir

    # Create the local chef config directory
    @local_chef_dir = File.expand_path(".chef", @local_dir)
    Dir.mkdir @local_chef_dir

    # Now we have a .chef dir we can include chef, and chef_config_dir will get set to what we want
    require 'chef'
    require 'chef/knife'
    require 'chef/knife/select'
    require 'chef/knife/core/text_formatter'

    # Generate the sample alias lists for selection
    @alias_list = {
          "oss-server" => {
            "url" => "http://oss-server:4000",
            "user" => "a_user",
            "validation_user" => "chef-validator",
            "validation_key" => "oss-server-validator.pem"
          },
          "hosted-chef-myorg" => {
            "url" => "https://api.opscode.com/organizations/myorg",
            "key" => "b_user.api.opscode.com.pem"
          }
        }
    @select_file = File.expand_path("./select_list.rb", @local_chef_dir)
    @alias_list_overrides = {
          "hosted-chef-myotherorg" => {
            "url" => "https://api.opscode.com/organizations/myotherorg",
            "user" => "b_user",
          }
        }
    @select_file_overrides = File.expand_path("./select_list_overrides.rb", @local_chef_dir)

    # Test knife.rb
    @knife_config = File.expand_path("./knife.rb", @local_chef_dir)
    knife_config_contents = ""

    # Write out the files
    [ [ @select_file, @alias_list ],
        [ @select_file_overrides, @alias_list_overrides ],
        [ @knife_config, knife_config_contents ] ].each do |filename, contents|
      begin
        file = File.new(filename, File::CREAT|File::TRUNC|File::RDWR, 0644)
        file.flock(File::LOCK_EX)
        tmp_file = Tempfile.new("#{File.basename(file)}",
                    "#{File.dirname(file)}")
        PP::pp contents, tmp_file
        tmp_file.flush
        tmp_file.close
        FileUtils.cp tmp_file, file
      rescue Exception => e
        ui.error "Error creating #{file}"
        raise e
      ensure
        file.flock(File::LOCK_UN)
        file.close
        tmp_file.close
        tmp_file.unlink
      end
    end
  end

  config.after(:all) do
    # Delete the example files created
    begin
      File.delete(@select_file, @select_file_overrides, @knife_config)
      Dir.delete(@local_chef_dir)
    rescue Exception => e
      # Ignore errors
    end
  end
end

# Validate our module reads the select_list in correctly
describe "HPCS::read_select_list" do
  it "Reads the select_list and select_list_overrides files" do
    aliases_read = HPCS::read_select_list
    aliases_read.should eq(@alias_list.merge(@alias_list_overrides))
  end
end

describe "HPCS::Select" do
  before(:each) do
    @stdout = StringIO.new ""
    @stderr = StringIO.new ""
    @stdin = StringIO.new ""
    @replace_ui = Chef::Knife::UI.new(@stdout, @stderr, @stdin, {})
    HPCS::SelectList.any_instance.stub(:ui).and_return(@replace_ui)
    @select = HPCS::Select.new
    @select.ui = @replace_ui
  end

  context "with no arguments" do
    describe "run" do
      it "returns a list of servers" do
        expect { @select.run }.to raise_error SystemExit
        @stdout.string.split.compact.should =~ @alias_list.merge(@alias_list_overrides).keys
      end
    end
  end

  context "with one argument" do
    describe "run with existing alias" do
      it "returns string to set environment variable" do
        use_alias = "oss-server"
        @select.name_args = [ use_alias ]
        @select.run 
        @stdout.string.should eq("export CHEF_SERVER_ALIAS=#{use_alias}\n")
      end
    end
    describe "run with non-existing alias" do
      it "returns a list of servers" do
        use_alias = "bad-server"
        @select.name_args = [ use_alias ]
        @select.run
        @stdout.string.should eq("echo \"No such alias: #{use_alias}\"\n")
      end
    end
  end

  context "with more than one argument" do
    describe "run" do
      it "informs the user of the problem" do
        @select.name_args = [ "oss-server", "hosted-chef-myorg" ]
        expect { @select.run }.to raise_error SystemExit
        @stderr.string.should
            eq("ERROR: Please choose from the following list of chef server aliases:\n")
        @stdout.string.split.compact.should =~ @alias_list.merge(@alias_list_overrides).keys
      end
    end
  end
end

describe "HPCS::SelectList" do
  before(:each) do
    @select_list = HPCS::SelectList.new
    @stdout = StringIO.new ""
    @stderr = StringIO.new ""
    @stdin = StringIO.new ""
    @select_list.ui = Chef::Knife::UI.new(@stdout, @stderr, @stdin, @select_list.ui.config)
  end

  context "with no arguments" do
    describe "run" do
      it "returns a list of servers" do
        @select_list.run
        @stdout.string.split.compact.should =~ @alias_list.merge(@alias_list_overrides).keys
      end
    end
    describe "run with full" do
      it "returns a list of servers" do
        @select_list.config[:full] = true
        @select_list.run
        output = Chef::Knife::Core::TextFormatter.new(@alias_list.merge(@alias_list_overrides),
                                                       @select_list.ui).formatted_data
        @stdout.string.should eq(output)
      end
    end
    describe "run with format json" do
      it "returns a list of servers" do
        @select_list.config[:format] = "json"
        @select_list.run
        Array.try_convert(eval(@stdout.string)).should \
            =~ @alias_list.merge(@alias_list_overrides).keys
      end
    end
    describe "run with full and format json" do
      it "returns a list of servers" do
        @select_list.config[:format] = "json"
        @select_list.config[:full] = true
        @select_list.run
        JSON.parse(@stdout.string).should eq(@alias_list.merge(@alias_list_overrides))
      end
    end
  end
end
