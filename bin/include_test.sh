#! /bin/bash
function assert () {
    local EXPECTED_VALUE=$1
    local ACTUAL_VALUE=$2
    local CONTEXT=${3:-debug}
    if [[ "$EXPECTED_VALUE" != "$ACTUAL_VALUE" ]]; then
        echo "$CONTEXT, expected: $EXPECTED_VALUE, but received: $ACTUAL_VALUE"
        return 1
    fi
    return 0
}
