#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

t=$(readlink -m "$BASH_SOURCE/../t")
b=$(readlink -m "$BASH_SOURCE/../BUILDROOT")

e=0

R="[38;5;208m\u25CF[0m"
F="[38;5;167m\u2718[0m"
P="[38;5;106m\u2714[0m"

mkdir -p "$b/t"

count=0

for f in $t/test_*.sh ; do
    ff=t/${f##*/}

    (( ++count ))

    printf " $R  %s" "$ff"

    if bash -x $f 1>$b/$ff.o 2>$b/$ff.e ; then
        printf "\r $P  %s\n" "$ff"
    else
        :>$b/$ff.f

        printf "\r $F  %s\n" "$ff"
        e=1
    fi
done

if [[ $1 == *.xml ]] ; then
    cat >$1 <<JUNIT
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="${count}">
$(for f in $b/t/*.o ; do
    ff=${f##*/}
    fn=${ff%.o}

    printf ' <testcase classname="t" name="%s">\n' "$fn"

    printf '  <system-out><![CDATA[\n'
    strings $b/t/$fn.o
    printf '  ]]></system-out>\n'

    printf '  <system-err><![CDATA[\n'
    strings $b/t/$fn.e
    printf '  ]]></system-err>\n'

    if [[ -e $b/t/$fn.f ]] ; then
        printf '<failure type="error">Test failed - see output</failure>\n'
    fi

    printf ' </testcase>\n'
done)
</testsuite>
JUNIT
fi

exit $e
