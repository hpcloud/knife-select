# Knife::Select

Knife plugin to allow listing of available chef servers and organisations and selection thereof

## Installation

Simply install the gem:

    $ gem install knife-select

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
