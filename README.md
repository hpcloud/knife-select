# Knife::Select

Knife plugin to allow listing of available chef servers and organisations and selection thereof

## Installation

Simply install the gem:

    $ gem install knife-select

## Setup

In order to use knife-select you need to first configure a select\_list.rb file to hold the
configuration details of the servers that you wish to connect to.  The file is eval'ed and must
result in the return of a hash, as interpreted by the Hash.try\_convert method.

The expected hash structure is alias as key name which should contain a hash of attributes for
that key.  All attributes for a key are optional in the file, but after processing of the
select\_list.rb and select\_list\_overrides.rb files the url key must be set to make the alias of
any use.

```text
select\_list[<alias>] = {
      'url' => "chef server url",
      'user' => "username to connect as",
      'key' => "key to use for authentication as <user>",
      'validation_user' => "validation user for the server",
      'validation_key' => "key to use for authentication as <validation_user>",
    }
```

Typically the select\_list.rb file would be placed into source control and shared amongst a team,
and as such would have only the generically applicable settings of 'url', 'validation_user' and
'validation_key'.  Then individual users would provide overrides within their own local
select\_list\_overrides.rb file for 'user' and 'key' as necessary.

The knife.rb can be used to provide defaults for values not specified, as shown in the example
provided within this code, e.g.:

```ruby
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
```

## Usage

Commands take the form of:

<pre>
    $ knife select <subcommand> ...
</pre>

Use the built-in help to determine exact syntax

### knife select [chef\_server\_alias]

Choose the chef server to interact with, prints the export command needed to set the
environment variable (as you can't change the parents environment, obviously).

Invoke as 'eval "knife select [chef\_server\_alias]"' to autoset the CHEF\_SERVER\_ALIAS

With no argument is an alias for "knife select list"

### knife select new CHEF\_SERVER\_ALIAS]

Add a new server into the list

This will ask for the url, user and key file for the chef server

### knife select list

Print a list of servers known to knife select

## Contributing

Please submit a pull request

# License and Authors

Author: Jon-Paul Sullivan (<jonpaul.sullivan@hp.com>)

```text
Copyright 2012-2013 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
