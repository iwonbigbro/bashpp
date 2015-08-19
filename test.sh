#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

t=$(readlink -m "$BASH_SOURCE/../t")
b=$(readlink -m "$BASH_SOURCE/../BUILDROOT")

rm -rf $b/t

e=0

bash_opts=

R="[38;5;208m$(printf "\x25\xCF" | iconv -f utf-16be)[0m"
S="[38;5;208m$(printf "\x25\xBA" | iconv -f utf-16be)[0m"
F="[38;5;167m$(printf "\x27\x18" | iconv -f utf-16be)[0m"
P="[38;5;106m$(printf "\x27\x14" | iconv -f utf-16be)[0m"

mkdir -p "$b/t"

trap "true" INT

if [[ $DEBUG == 1 ]] ; then
    bash_opts+=-x
fi

function assert() {
    local lines=() lineno=${BASH_LINENO[0]}

    mapfile -tn1 -s$((lineno-1)) lines <"${BASH_SOURCE[1]}"

    printf "ASSERT: ${BASH_SOURCE[1]##*/}:$lineno: %s\n" "$lines"

    exit 1
}
export USE_ASSERT="function $(declare -f assert)"

if hash time 2>/dev/null ; then
function time_fn() {
    \time -f " - took %e (S:%S, U:%U) secs" -o $b/$ff.t "$@"
}
else
function time_fn() {
    :> $b/$ff.t
    "$@"
}
fi

while true ; do
    count=0

    for f in $t/test_${1:-*}.sh ; do
        ff=t/${f##*/}

        (( ++count ))

        printf " $R  %s" "$ff"

        export bash_opts

        ret=0
        time_fn bash $bash_opts $f 0</dev/null 1>$b/$ff.o 2>&1 || ret=$?

        if (( ret == 0 )) ; then
            printf "\r $P  %s[38;5;106m%s[0m\n" "$ff" "$(tail -1 $b/$ff.t)"
        elif (( ret == 80 )) ; then
            :>$b/$ff.s

            printf "\r $S  %s[38;5;106m%s[0m\n" "$ff" "$(tail -1 $b/$ff.t)"
        else
            :>$b/$ff.f

            printf "\r $F  %s[38;5;167m%s[0m\n" "$ff" "$(tail -1 $b/$ff.t)"

            if [[ $VERBOSE == 1 ]] ; then
                while IFS=$'\0' read -r line ; do
                    printf "      [38;5;167m%s[0m\n" "$line"
                done < "$b/$ff.o"
            fi
            e=1
        fi
    done

    if [[ $CONTINUOUS == 1 ]] ; then
        sleep 5

        if (( ( $? - 128 ) == 2 )) ; then
            break
        fi

        printf "%s\n" " ----- "
    else
        break
    fi
done

if [[ ${JUNIT_XML_OUT:-} == *.xml ]] ; then
    cat >$JUNIT_XML_OUT <<JUNIT
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="${count}">
$(for f in $b/t/*.o ; do
    ff=${f##*/}
    fn=${ff%.o}

    printf ' <testcase classname="t" name="%s">\n' "$fn"

    printf '  <system-out><![CDATA[\n'
    strings $b/t/$fn.o
    printf '  ]]></system-out>\n'

    if [[ -e $b/t/$fn.f ]] ; then
        printf '<failure type="error">Test failed - see output</failure>\n'
    elif [[ -e $b/t/$fn.s ]] ; then
        printf '<skipped/>\n'
    fi

    printf ' </testcase>\n'
done)
</testsuite>
JUNIT
fi

exit $e
