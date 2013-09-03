#!/bin/bash

#
# Unset CHEF_SERVER_ALIAS so that stray knife commands don't talk to a server
#
function unset_chef() {
    unset CHEF_SERVER_ALIAS
}

#
# Set CHEF_SERVER_ALIAS so that knife commands target the specified chef server/organisation
#
function set_chef() {
    local chef_alias=${1:-""}

    if [[ "$(gem list -i knife-select)" == "true" ]]
    then
        if [[ -z "${chef_alias}" ]]
        then
            knife select list
            return $?
        fi
        eval "$(knife select $chef_alias)"
    else
        echo "Error: knife-select gem not installed"
    fi
}

