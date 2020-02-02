#!/bin/bash
spinner() {
    local i sp n
    sp='/-\|'
    n=${#sp}
    printf ' '
    while sleep 0.1; do
        printf "%s\b" "${sp:i++%n:1}"
    done
}

printf 'Doing important work '
spinner &

sleep 30  # sleeping for 10 seconds is important work

kill "$!"
