#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

t=$(readlink -m "$BASH_SOURCE/../t")
e=0

R="[38;5;208m\u25CF[0m"
F="[38;5;167m\u2718[0m"
P="[38;5;106m\u2714[0m"

for f in $t/test_*.sh ; do
    ff=t/${f##*/}

    printf " $R  %s" "$ff"

    if bash $f >/dev/null ; then
        printf "\r $P  %s\n" "$ff"
    else
        printf "\r $F  %s\n" "$ff"
        e=1
    fi
done

exit $e
