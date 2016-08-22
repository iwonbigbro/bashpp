#!/usr/bin/env bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

# LICENSE: BSD
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

set -euo pipefail

exec 100<&0

bashpp=$(readlink -f "$BASH_SOURCE")
bashpp_dir=${bashpp%/*}

BASHINC=${BASHINC:-}

declare -A DEFS=()
declare -A MACROS=()

output="/dev/stdout"

VERBOSE=${VERBOSE:-0}
DEBUG=${DEBUG:-${DEBUG_LEVEL:-0}}
DEBUG_STATES=${DEBUG_STATES:-}
DEBUG_STATES_FLAG=0
DEBUG_LINENO=${DEBUG_LINENO:-0}
ERROR_LINE=${ERROR_LINE:-1}
ERROR_MAX=${ERROR_MAX:-10}
BUF_MAX=${BUF_MAX:-4096}
FILE_MAX=${FILE_MAX:-0}

RET_PROCHR_CONT=1
RET_PROCHR_PUSHBUF=2
RET_PROCHR_POPSTATE=4
RET_PROCHR_SKIP=8

OUTPUT_LINES=0
SECONDS=0

if (( BUF_MAX > FILE_MAX )) ; then
    BUF_MAX=$FILE_MAX
fi

CR=$'\r'
LF=$'\n'
CRLF=$'\r\n'
TAB=$'\t'

WHITESPACE=$'\r\n\t '

errors=0
warnings=0
lineno=0

msg_errorline_lock=0

tty_stdout=0
tty_stderr=0
tty_stdin=0
tty=0

if [[ -t 0 ]] ; then
    tty_stdin=1
    tty=1
fi

if [[ -t 1 ]] ; then
    tty_stdout=1
    tty=1
fi

if [[ -t 2 ]] ; then
    tty_stderr=1
    tty=1
fi

states=1
state_names=( "eof" )
eof=0

files=()

function cleanup() {
    local exitcode=$?

    if (( exitcode != 0 )) ; then
        if [[ $output != "/dev/"* ]] ; then
            rm -f $output
        fi
    fi
}
trap 'cleanup' EXIT

function assoc_arrcpy() {
    declare -p $1 | sed 's?^[^=]\+=??'
}

function callable() {
    declare -F $1 >/dev/null 2>&1 || [[ -x $1 ]]
}

function msgtype_colour() {
    local tag=${1%%_*}
    local on= off=

    if (( tty )) ; then
        case $tag in
        (stop*)      on="[1m[38;5;124m" ;;
        (error*)     on="[1m[38;5;167m" ;;
        (warning*)   on="[1m[38;5;213m" ;;
        (info*)      on="[1m[38;5;106m" ;;
        (debug*)     on="[1m[38;5;105m" ;;
        esac

        off="[39m[0m"
    fi

    printf "${on}%s${off}" "$tag"
}

function bashpp_msg() {
    local msgtype=$1
    shift

    local funcname=${FUNCNAME[1]:-main}

    if [[ $funcname == +(msg|die|debug|info|warn)* ]] ; then
        funcname=${FUNCNAME[2]:-main}
    fi

    local msg=${*///^[}

    printf >&2 "${bashpp##*/}: $msgtype:${funcname:+ $funcname:} %s\n" "$msg"
}

function msg_errorline() {
    local stdin=$1
    local errline=

    if (( msg_errorline_lock != 0 )) ; then
        return 0
    fi

    (( ++msg_errorline_lock )) || true

    if (( stdin )) ; then
        errline="${buf##*$LF}..."
    else
        errline=$(awk 'NR == '$lineno' { print ; exit }' "$file")
    fi

    if [[ ${c:-} == $LF ]] && (( ( ${#errline} + 1 ) != charno )) ; then
        die "incorrect charno: $charno != (${#errline} + 1)"
    fi

    errline="${errline//[$CRLF]/ }  "

    local esc_errline=${errline///^[}

    local indicator=${errline:0:$charno}
          indicator=${indicator///^[}
          indicator=${indicator//?/.}
          indicator=${indicator%.}^

    local parsed=${errline:0:$charno-1} \
          current=${errline:$charno-1:1} \
          unparsed=${errline:$charno}

    if (( tty )) ; then
        printf >&2 "[38;5;105m%s[4m[38;5;167m%s[0m%s\n[38;5;64m%s[0m\n" \
            "  ${parsed///^[}" "${current///^[}" "${unparsed///^[}" \
            "  $indicator"
    else
        printf >&2 "%s%s%s\n%s\n" \
            "  ${parsed///^[}" "${current///^[}" "${unparsed///^[}" \
            "  $indicator"
    fi

    (( --msg_errorline_lock )) || true
}

function msg() {
    local msgtype=$1
    local msgtype_colour=$(msgtype_colour "$msgtype")
    local show_errorline=1
    shift

    local msg=${*///^[}
          msg=${msg//[$CRLF]/\\n}

    if [[ ! ${file:-} ]] ; then
        bashpp_msg "$msgtype_colour" "$*"
    else
        if [[ $msgtype != +(error|warning|debug) ]] ; then
            show_errorline=0
        fi

        if (( tty )) ; then
            printf >&2 "[0m"
        fi

        if [[ $file == "/dev/stdin" ]] ; then
            printf >&2 "<stdin>:$lineno:$charno $msgtype_colour: %s\n" "$msg"

            if (( show_errorline )) ; then
                msg_errorline 1
            fi
        else
            printf >&2 "$file:$lineno:$charno $msgtype_colour: %s\n" "$msg"

            if (( show_errorline )) ; then
                msg_errorline 0
            fi
        fi
    fi
}

function err() {
    if (( lineno == 0 )) ; then
        die "$@"
    fi

    (( ++errors )) || true

    msg "error" "$errors: $*"

    if (( errors >= ERROR_MAX )) ; then
        local p=$(( ( fileoffset * 100 ) / filesize ))

        msg "stop" "stopping at ${p}%, too many errors"
        exit 1
    fi
}

function stacktrace() {
    local i=0 total=0

    if (( $# )) ; then
        printf >&2 "[1m[38;5;167mTraceback:[0m\n"
        printf >&2 "  [38;5;167m%s:%d: %s()[0m\n" "$@"

        (( ++total )) || true
    fi


    while (( ++i <= ${#BASH_LINENO[@]} )) ; do
        local s=${BASH_SOURCE[i]:-$BASH_SOURCE} \
              f=${FUNCNAME[i]:-main} \
              l=${BASH_LINENO[i-1]}

        if [[ $f == +(die|stacktrace) ]] ; then
            continue
        elif (( l == 0 )) ; then
            continue
        fi

        if (( ++total == 1 )) ; then
            printf >&2 "[1m[38;5;167mTraceback:[0m\n"
        fi

        printf >&2 "  [38;5;167m%s:%s():%d: %s[0m\n" "$s" "$f" "$l" \
            "$(awk -v l=$l 'NR == l { print }' < "$s")"
    done
}

set -E
trap 'stacktrace "$BASH_SOURCE" "$LINENO" "${FUNCNAME:-main}"' ERR

function die() {
    local funcname=${FUNCNAME[1]:-}
          funcname=${funcname:+$funcname }

    stacktrace
    msg "error" "$*"

    exit 1
}

if (( BASH_VERSINFO[0] < 4 || ( BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 1 ) )) ; then
    die "minimum version '4.1' required"
fi

function warn() {
    (( ++warnings ))

    msg "warning" "$*"
}

function info() {
    if (( VERBOSE )) ; then
        msg "info" "$*"
    fi
}

function info_progress() {
    local p=0
    
    if (( filesize > 0 )) ; then
        p=$(( ( fileoffset * 100 ) / filesize ))
    fi

    if (( DEBUG )) ; then
        debug "${p}% complete"
    elif (( VERBOSE )) ; then
        info "${p}% complete"
    fi
}

function debug() {
    if (( DEBUG )) ; then
        if (( DEBUG_STATES_FLAG == 1 )) ; then
            return
        elif (( DEBUG_LINENO > 0 && lineno < DEBUG_LINENO )) ; then
            return
        fi

        local fn=${FUNCNAME[1]:-main}

        if [[ $fn == "debug_"* ]] ; then
            fn=${FUNCNAME[2]:-main}
        fi

        msg "debug" "$fn(): $*"
    fi
}

function debug_l() {
    if (( DEBUG > $1 )) ; then
        local l=$1
        shift

        if (( DEBUG_STATES_FLAG == 1 )) ; then
            return
        elif (( DEBUG_LINENO > 0 && lineno < DEBUG_LINENO )) ; then
            return
        fi

        msg "debug_$l" "${FUNCNAME[1]:-main}(): $*"
    fi
}

function describe_char() {
    case $1 in
    ($CR) echo "carriage-return" ;;
    ($LF) echo "line-feed" ;;
    ($CRLF) echo "<CRLF>" ;;
    ($TAB) echo "tab" ;;
    ($WHITESPACE) echo "whitespace" ;;
    (" ") echo "space" ;;
    (*) printf "%02X" "'$1" ;;
    esac
}

function initialise() {
    local fn= \
          name= \
          exp= \
          x=

    local state_names=( "eof" )

    states=${#state_names[@]}

    while read x x fn ; do
        if [[ $fn == process_char_state_* ]] ; then
            name=${fn#process_char_state_}
            state_names+=( $name )

            printf -v $name "%d" $states
            export $name

            (( ++states ))
        fi
    done < <(declare -F)

    local debug_states=${DEBUG_STATES//,/ }

    DEBUG_STATES=

    for name in "${state_names[@]}" ; do
        printf -v $name "%d" $states
        export $name

        (( ++states ))

        local added=0

        if [[ $debug_states ]] ; then
            for exp in $debug_states ; do
                if [[ $name == $exp && " $DEBUG_STATES " != *" $name "* ]] ; then
                    DEBUG_STATES+=" $name"

                    (( ++added )) || true
                fi
            done

            if (( ! added )) ; then
                die "invalid state expression: $exp"
            fi
        fi
    done

    st_name_default="eof"
    st_default=$eof

    if (( ${#DEBUG_STATES} > 0 )) ; then
        DEBUG_STATES_FLAG=1

        if (( ! DEBUG )) ; then
            DEBUG=1
        fi
    elif (( DEBUG_LINENO > 0 && ! DEBUG )) ; then
        DEBUG=1
    fi
}

function add_include_dir() {
    if [[ ! $1 ]] ; then
        die "No directory specified"
    elif [[ ! -d $1 ]] ; then
        die "No such directory: $1"
    fi

    if [[ ":${BASHINC:-}:" != *":$1:"* ]] ; then
        BASHINC+=":$1"
    fi
}

function definefn() {
    err "macro functions currently not supported"
}

function is_define() {
    if [[ ! $1 ]] ; then
        die "ambiguous request"
    fi

    [[ ${DEFS[$1]+set} == "set" ]]
}

function is_macro() {
    if [[ ! $1 ]] ; then
        die "ambiguous request"
    fi

    [[ ${!MACROS[$1]:-} ]]
}

function define() {
    local name= \
          parens= \
          define=${2:-1}

    if [[ $1 =~ ^([A-Za-z_][A-Za-z0-9_]*)(\(.+\))?$ ]] ; then
        name=${BASH_REMATCH[1]}
        parens=${BASH_REMATCH[2]:-}

        if [[ $parens ]] ; then
            parens=${parens#(}
            parens=${parens%)}
        fi
    else
        err "illegal definition: $1"
    fi

    info "-D $name=$define"

    if [[ $parens ]] ; then
        definefn "$name" "$parens" "$define"
        return 0
    fi

    DEFS[$name]=$define
}

function undef() {
    info "-U $1"

    unset DEFS[$1]
    unset MACROS[$1]
}

function add_define() {
    local name=${1%%=*} \
          define=${1#*=}

    if [[ $1 == *"="* ]] ; then
        define "${1%%=*}" "${1#*=}"
    else
        define "$1" 1
    fi
}

function remove_define() {
    undef "$1"
}

function debug_state_change() {
    if (( DEBUG_STATES_FLAG == 1 )) ; then
        if [[ " $DEBUG_STATES " == *" $1 "* ]] ; then
            DEBUG_STATES_FLAG=2
        fi
    fi

    debug "$st_name -> $1: '${c:-}' st_charno=$st_charno"

    if (( DEBUG_STATES_FLAG == 2 )) ; then
        if [[ " $DEBUG_STATES " != *" $1 "* ]] ; then
            DEBUG_STATES_FLAG=1
        fi
    fi
}

function in_state() {
    if [[ $st_name == $1 ]] ; then
        return 0
    elif [[ " ${state_stack[*]} " == *" $1 "* ]] ; then
        return 0
    fi

    return 1
}

function push_state() {
    debug_state_change "$1"

    state_stackbuf+=( "$st_buf" )
    state_stack+=( $st_name )

    (( ++state_stacklen )) || true

    st=${!1}
    st_name=$1
    st_charno=1
    st_buf=
}

function pop_state() {
    if (( state_stacklen == 0 || ${#state_stack[@]} != state_stacklen )) ; then
        die "state_stack accounting error"
    fi

    local i=$state_stacklen

    (( --i )) || true

    debug_state_change "${state_stack[i]}"

    st_name=${state_stack[i]}
    st_buf=${state_stackbuf[i]}
    st_charno=${#st_buf}
    st=${!st_name}

    unset state_stack[i]
    unset state_stackbuf[i]

    (( --state_stacklen )) || true
}

function switch_state() {
    debug_state_change "$1"

    st=${!1}
    st_name=$1
}

function push_heredoc() {
    debug "$hd -> $1"

    # Workaround for vim syntax highlighting error.
    local a="'" q='"'

    if [[ "$1" =~ ^${a}(.+)${a}$ ]] ; then
        debug "heredoc type = apos"

        hd_type=$apos
        hd=${BASH_REMATCH[1]}
    else
        debug "heredoc type = default"

        hd_type=$quote

        if [[ $1 =~ ^${q}(.+)${q}$ ]] ; then
            hd=${BASH_REMATCH[1]}
        else
            hd=$1
        fi
    fi

    heredoc_stacktype+=( "$hd_type" )
    heredoc_stack+=( $hd )

    (( ++heredoc_stacklen )) || true
}

function pop_heredoc() {
    if (( heredoc_stacklen == 0 )) ; then
        die "heredoc_stack accounting error"
    fi

    local cur_hd=$hd

    local i=$heredoc_stacklen

    hd=${heredoc_stack[i-1]}
    hd_type=${heredoc_stacktype[i-1]}

    unset heredoc_stack[i]
    unset heredoc_stackbuf[i]

    if (( --heredoc_stacklen == 0 )) ; then
        if (( st == heredoc )) ; then
            pop_state
        else
            die "unable to pop heredoc state"
        fi
    fi

    debug "$cur_hd -> $hd"
}

function freeze_buf() {
    freezebuf_stack+=( "${freezebuf_buf}" )
    freezebuf_buf=

    (( ++freezebuf ))

    debug "freezebuf=$freezebuf, freezebuf_stack=${#freezebuf_stack[*]}"
}

function thaw_buf() {
    if (( ! freezebuf )) ; then
        die "attempted to thaw empty freeze buffer"
    fi

    (( --freezebuf ))

    thawed_buf=$freezebuf_buf
    freezebuf_buf=${freezebuf_stack[freezebuf]}

    unset freezebuf_stack[freezebuf]

    debug "${#thawed_buf} bytes thawed"
}

function push_buf() {
    st_buf+=$1

    if (( SECONDS > 0 )) ; then
        info_progress

        SECONDS=0
    fi

    debug_l 2 "pushing: '$1'"

    if (( freezebuf )) ; then
        debug_l 2 "buffer frozen, freezebuf=$freezebuf"

        freezebuf_buf+=$1
    else
        if (( buf_ptr == fileoffset )) ; then
            die "duplicate calls to push_buf"
        fi

        buf+=$1

        if [[ "$1" == "$c" ]] ; then
            debug_l 2 "'$1' == '$c', moving buf_ptr=$fileoffset"

            buf_ptr=$fileoffset
        fi

        if (( flushbuf || ${#buf} > BUF_MAX )) ; then
            printf "%s" "$buf"

            flushbuf=0
            buf=
        fi

        if (( FILE_MAX > 0 && fileoffset > FILE_MAX )) ; then
            info "stopping at $fileoffset bytes"
            exit 1
        fi
    fi
}

function flush_buf() {
    if (( ${1:-0} )) ; then
        printf "%s" "$buf"

        flushbuf=0
        buf=
    else
        flushbuf=1
    fi
}

function process_directive_define() {
    local args=$1
    local line=$2

    if in_state ifdef_exclude ; then
        return 0
    elif [[ $args =~ ^([A-Za-z_][A-Za-z0-9_]*)[\ \t]+(.*)$ ]] ; then
        define "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"

        return 0
    elif [[ $args =~ ^([A-Za-z_][A-Za-z0-9_]*)$ ]] ; then
        define "${BASH_REMATCH[1]}" 1

        return 0
    fi

    err "illegal define: $line"

    return 1
}

function process_directive_else() {
    local args=$1
    local line=$2
    
    if (( st == ifdef_include )) ; then
        pop_state
        push_state ifdef_exclude
        freeze_buf
    elif (( st == ifdef_exclude )) ; then
        thaw_buf
        pop_state
        push_state ifdef_include
    else
        err "illegal else: $line"

        return 1
    fi
}

function process_directive_endif() {
    local args=$1
    local line=$2

    if (( st == ifdef_include )) ; then
        pop_state
    elif (( st == ifdef_exclude )) ; then
        thaw_buf
        pop_state
    else
        err "illegal endif: $line"

        return 1
    fi
}

function process_directive_error() {
    local args=$1
    local line=$2
    local a="'" q='"'
    local msg=

    if in_state ifdef_exclude ; then
        return 0
    elif [[ $args =~ ^\ *${a}(.+)${a}\ *$ ]] ; then
        msg=${BASH_REMATCH[1]}
    elif [[ $args =~ ^\ *${q}(.+)${q}\ *$ ]] ; then
        msg=${BASH_REMATCH[1]}
    elif [[ $args =~ ^\ *(.+)\ *$ ]] ; then
        msg=${BASH_REMATCH[1]}
    else
        err "illegal error: $line"

        return 1
    fi

    msg "error_directive" "${BASH_REMATCH[1]}"

    (( ++errors )) || true
}

function process_directive_ifdef() {
    local args=$1
    local line=$2

    if [[ $args =~ ^\ *([^$WHITESPACE]+)\ *$ ]] ; then
        local def=${BASH_REMATCH[1]}

        if [[ ${DEFS[$def]+set} == "set" ]] ; then
            debug "$def is defined"

            push_state ifdef_include
        else
            debug "$def is not defined"

            push_state ifdef_exclude
            freeze_buf
        fi

        return 0 
    fi

    err "illegal ifdef: $line"

    return 1
}

function process_directive_ifndef() {
    local args=$1
    local line=$2

    if [[ $args =~ ^\ *([^$WHITESPACE]+)\ *$ ]] ; then
        local def=${BASH_REMATCH[1]}

        if [[ ${DEFS[$def]+set} == "set" ]] ; then
            debug "$def is defined"

            push_state ifdef_exclude
            freeze_buf
        else
            debug "$def is not defined"

            push_state ifdef_include
        fi

        return 0 
    fi

    err "illegal ifdef: $line"

    return 1
}

function process_directive_include() {
    local args=$1
    local line=$2
    local includefile=
    local a="'" q='"'

    if in_state ifdef_exclude ; then
        return 0
    elif [[ $args =~ ^${q}(.+)${q}$ || $args =~ ^${a}(.+)${a}$ ]] ; then
        includefile=${BASH_REMATCH[1]}

        if [[ $includefile != /* ]] ; then
            includefile="$(dirname "$file")/$includefile"
        fi
    elif [[ $args =~ ^\<(.+)\>$ ]] ; then
        includefile=${BASH_REMATCH[1]}

        local d= found=0
        local IFS=':'

        debug "searching \$BASHINC include paths for: '$includefile'"

        for d in $BASHINC ; do
            if [[ -f $d/$includefile ]] ; then
                includefile=$d/$includefile
                found=1

                debug "found include in: '$d'"

                break
            fi
        done

        unset IFS

        if (( ! found )) ; then
            err "file not found: $includefile"

            return 1
        fi
    fi

    if [[ $includefile ]] ; then
        debug "iterating include file: '$includefile'"

        iter_file "$includefile"

        return 0
    else
        err "illegal include: $line"
    fi

    return 1
}

function process_char_state_apos() {
    if [[ $c == "'" ]] ; then
        pop_state
    elif [[ $c == '' ]] ; then
        push_state escape_sequence

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_arithmetic() {
    if [[ $c == '\' ]] ; then
        push_state escape
    elif [[ $c == '(' ]] ; then
        push_state parens
    elif [[ ${pr_c}$c == '))' ]] ; then
        pop_state
    fi
}

function process_char_state_bracket_c() {
    if [[ $c == '}' ]] ; then
        pop_state
    else
        process_char_state_parsing || return $?
    fi
}

function process_char_state_bracket_s() {
    if [[ $c == '\' ]] ; then
        push_state escape
    elif [[ $c == '[' ]] ; then
        switch_state conditional
    elif [[ $c == ']' ]] ; then
        pop_state
    fi
}

function process_char_state_comment() {
    if [[ $c == [$CRLF] ]] ; then
        pop_state
    fi
}

function process_char_state_conditional() {
    if (( st_charno == 1 )) ; then
        if [[ $c != ' ' ]] ; then
            warn "missing whitespace in conditional expression"

            if [[ $c == [\-=\!\<\>] ]] ; then
                push_state conditional_operator
            fi
        fi
    fi

    if [[ $pr_c == [$WHITESPACE] && $c == [\-\!=] ]] ; then
        push_state conditional_operator
    elif [[ $c == '\' ]] ; then
        push_state escape
    elif [[ $c == "'" ]] ; then
        push_state apos
    elif [[ $c == '"' ]] ; then
        push_state quote
    elif [[ $c == '(' ]] ; then
        push_state parens
    elif [[ ${pr_c}$c == '))' ]] ; then
        err "exiting conditional too early"
        pop_state
    elif [[ ${pr_c}$c == ']]' ]] ; then
        pop_state
    fi
}

function process_char_state_conditional_operator() {
    if [[ $c == [$WHITESPACE] ]] ; then
        case $st_buf in
        (-[abcdefghklnoprstuvwxzGLNORS]) ;;
        (-ef|-eq|-ge|-gt|-le|-lt|-ne|-nt|-ot) ;;
        (==|!=|!|\&\&|\|\||\|\&) ;;
        (=~)
            push_buf "$c"
            pop_state
            switch_state conditional_regex

            return $RET_PROCHR_SKIP
            ;;
        (=)
            warn "posix operator in non-posix conditional"
            ;;
        (*)
            err "unrecognized operator: '$st_buf'"
            ;;
        esac

        pop_state

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_conditional_whitespace() {
    if [[ $c != [$WHITESPACE] ]] ; then
        pop_state

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_conditional_end() {
    if (( st_charno < 2 )) ; then
        return 0
    elif [[ $c == [$WHITESPACE] ]] ; then
        case $st_buf in
        ('&&'|'||'|'-a'|'-o')
            pop_state
            push_state conditional

            if [[ $st_buf == "-a" ]] ; then
                warning "posix operator in non-posix conditional: use '&&'"
            elif [[ $st_buf == "-o" ]] ; then
                warning "posix operator in non-posix conditional: use '||'"
            fi

            return $RET_PROCHR_CONT
            ;;
        (']]')
            pop_state

            return $RET_PROCHR_CONT
            ;;
        esac
    fi

    err "unexpected characters in conditional: '$st_buf'"

    pop_state
}

function process_char_state_conditional_regex() {
    if [[ $c == '\' ]] ; then
        push_state escape
    elif [[ $c == [$WHITESPACE] ]] ; then
        pop_state
        push_state conditional_end
        push_state conditional_whitespace

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_directive() {
    debug_l 2 "st_charno=$st_charno, c=$c"

    if (( st_charno == 2 )) && [[ $c != [a-z] ]] ; then
        thaw_buf
        switch_state comment
        push_buf "$thawed_buf"

        return $RET_PROCHR_CONT
    elif (( ${#c} == 0 )) || [[ $c == [$CRLF] ]] ; then
        thaw_buf

        local directive= directive_params=
        read directive directive_params <<<"${thawed_buf:1}"

        pop_state

        local fn="process_directive_$directive"

        if callable $fn ; then
            if $fn "$directive_params" "$thawed_buf" ; then
                return $RET_PROCHR_SKIP
            fi
        else
            err "invalid directive: $directive"
        fi

        push_buf "$thawed_buf"
    fi
}

function process_char_state_directive_heredoc() {
    if (( st_charno == 2 )) && [[ $c != [a-z] ]] ; then
        thaw_buf
        pop_state

        push_buf "$thawed_buf"

        return $RET_PROCHR_CONT
    elif [[ $c == [$CRLF] ]] ; then
        thaw_buf

        local directive= directive_params=
        read directive directive_params <<<"${thawed_buf:1}"

        pop_state

        local fn="process_directive_$directive"

        if callable $fn ; then
            if $fn "$directive_params" "$thawed_buf" ; then
                return $RET_PROCHR_SKIP
            fi
        else
            err "invalid directive: $directive"
        fi

        push_buf "$thawed_buf"
    fi
}

function process_char_state_dollar() {
    pop_state

    if [[ $c == [*@\#\?\-\$\!0-9] ]] ; then
        true
    elif [[ $c == "'" ]] ; then
        push_state apos
    elif [[ $c == '"' ]] ; then
        push_state quote
    elif [[ $c == '{' ]] ; then
        push_state expandparam
    elif [[ $c == '(' ]] ; then
        push_state expandcmd
    elif [[ $c == [A-Za-z_] ]] ; then
        push_state expandvar

        return $RET_PROCHR_CONT
    else
        err "unexpected token in parameter expansion"
    fi
}

function process_char_state_escape() {
    push_buf "$c"
    pop_state

    return $RET_PROCHR_SKIP
}

function process_char_state_escape_sequence() {
    if (( st_charno == 1 )) ; then
        if [[ "${st_buf}$c" == '' ]] ; then
            return 0
        fi
    elif (( st_charno == 2 )) ; then
        if [[ "${st_buf}$c" == '[' ]] ; then
            return 0
        fi
    elif [[ $c == [0-9\;] ]] ; then
        return 0
    elif [[ $c == 'm' ]] ; then
        pop_state
        return 0
    fi

    warn "unexpected character in escape sequence"

    pop_state

    return $RET_PROCHR_CONT
}

function process_char_state_expandcmd() {
    if (( st_charno == 2 )) && [[ "${st_buf}$c" == '((' ]] ; then
        switch_state arithmetic
    elif [[ $c == ')' ]] ; then
        pop_state
    else
        if [[ $c == [$CRLF] ]] ; then
            warn "unescaped multiline command substitution"
        fi

        process_char_state_parsing || return $?
    fi
}

function process_char_state_expandparam() {
    if (( st_charno == 1 )) ; then
        if [[ $c != [A-Za-z0-9_\!\*\@] && $c != '#' ]] ; then
            err "malformed parameter expansion expression"
        fi
    elif (( st_charno == 2 )) && [[ $st_buf == [0-9] ]] ; then
        if [[ $c != '}' ]] ; then
            err "malformed parameter expansion expression"
        fi

    # TODO: Handle expressions.

    elif [[ $c == '}' ]] ; then
        pop_state
    fi
}

function process_char_state_expandvar() {
    if (( st_charno == 1 )) ; then
        if [[ $c == [0-9] ]] ; then
            push_buf "$c"
            pop_state

            return $RET_PROCHR_SKIP
        fi
    elif [[ $c != [A-Za-z0-9_] ]] ; then
        pop_state

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_heredoc() {
    if [[ $c == [$CRLF] ]] ; then
        debug "checking hd_buf($hd_buf) == hd($hd)"

        if [[ $hd_buf == $hd ]] ; then
            pop_heredoc
        fi

        hd_buf=
    else
        if (( charno == 1 )) && [[ $c == '#' ]] ; then
            push_state directive_heredoc
            freeze_buf

            return $RET_PROCHR_CONT
        elif (( hd_type == quote )) ; then
            if [[ $c == '$' ]] ; then
                push_state dollar
            elif [[ $c == '`' ]] ; then
                push_state tick
            fi
        fi

        hd_buf+="$c"
    fi
}

function process_char_state_heredoc_inline() {
    thaw_buf

    if [[ $thawed_buf == *[$CRLF]* ]] ; then
        warn "herestring contains new-line: ${thawed_buf//[$CRLF]/\\n}"
    fi

    push_buf "$thawed_buf"
    pop_state
}

function process_char_state_heredoc_tag() {
    pop_state

    if [[ $c == '<' ]] ; then
        push_state heredoc_inline
        freeze_buf
        push_state parsing_string

        return 0
    fi

    push_state heredoc_tagged
    freeze_buf
    push_state parsing_string

    return $RET_PROCHR_CONT
}

function process_char_state_heredoc_tagged() {
    thaw_buf

    if [[ $thawed_buf == *[$CRLF]* ]] ; then
        warn "heredocument tag contains new-line: ${thawed_buf//[$CRLF]/\\n}"
    fi

    local tag=$thawed_buf

    if [[ ${tag:0:1} == "-" ]] ; then
        tag=${tag:1}
    fi

    push_heredoc "$tag"
    push_buf "$thawed_buf"
    pop_state

    return $RET_PROCHR_CONT
}

function process_char_state_ifdef_include() {
    process_char_state_parsing || return $?
}

function process_char_state_ifdef_exclude() {
    # Enter the directive state only when we hit a suspected directive.
    if (( charno == 1 )) && [[ $c == '#' ]] ; then
        process_char_state_parsing || return $?
    fi
}

function process_char_state_number() {
    if [[ $c != [0-9] ]] ; then
        pop_state

        return $RET_PROCHR_CONT
    fi
}

function process_char_state_parens() {
    if (( st_charno == 2 )) && [[ "${st_buf}$c" == '((' ]] ; then
        switch_state arithmetic
    elif [[ $c == ')' ]] ; then
        pop_state
    else
        process_char_state_parsing || return $?
    fi
}

function process_char_state_parsing() {
    if (( heredoc_stacklen > 0 )) && [[ $c == [$CRLF] ]] ; then
        push_state heredoc
    elif [[ $c == '#' ]] ; then
        if (( charno == 1 )) ; then
            push_state directive
            freeze_buf
        else
            push_state comment
        fi
    elif [[ $c == '$' ]] ; then
        push_state dollar
    elif [[ $c == '`' ]] ; then
        push_state tick
    elif [[ $c == '(' ]] ; then
        push_state parens
    elif [[ $c == '{' ]] ; then
        push_state bracket_c
    elif [[ $c == '[' ]] ; then
        push_state bracket_s
    elif [[ $c == '"' ]] ; then
        push_state quote
    elif [[ $c == "'" ]] ; then
        push_state apos
    elif [[ $c == '<' ]] ; then
        push_state redirect_in
    elif [[ $c == '>' ]] ; then
        push_state redirect_out
    elif [[ $c == [A-Za-z_] ]] ; then
        push_state word
        freeze_buf
    fi
}

function process_char_state_parsing_string() {
    if [[ $c == [$WHITESPACE] ]] ; then
        pop_state

        return $RET_PROCHR_CONT
    fi

    process_char_state_parsing || return $?
}

function process_char_state_quote() {
    if [[ $c == '\' ]] ; then
        push_state escape
    elif [[ $c == '' ]] ; then
        push_state escape_sequence

        return $RET_PROCHR_CONT
    elif [[ $c == '$' ]] ; then
        push_state dollar
    elif [[ $c == '`' ]] ; then
        push_state tick
    elif [[ $c == '"' ]] ; then
        pop_state
    fi
}

function process_char_state_redirect_fd() {
    if (( st_charno == 1 )) ; then
        if [[ $c == [0-9] ]] ; then
            return 0
        fi
    elif [[ $c == [0-9] ]] ; then
        return 0
    elif [[ $c == [\;$WHITESPACE] ]] ; then
        pop_state

        return 0
    fi

    err "unexpected character in redirect"

    pop_state

    return $RET_PROCHR_CONT
}

function process_char_state_redirect_in() {
    pop_state

    # TODO: Process substitution.

    if [[ $c == '<' ]] ; then
        push_state heredoc_tag
    elif [[ $c == '&' ]] ; then
        push_state redirect_fd
    else
        return $RET_PROCHR_CONT
    fi
}

function process_char_state_redirect_out() {
    pop_state

    if [[ $c == '>' ]] ; then
        true
    elif [[ $c == '&' ]] ; then
        push_state redirect_fd
    else
        return $RET_PROCHR_CONT
    fi
}

function process_char_state_tick() {
    if [[ $c == '`' ]] ; then
        pop_state
    else
        process_char_state_parsing || return $?
    fi
}

function process_char_state_word() {
    if [[ $c != [0-9A-Za-z_] ]] ; then
        pop_state
        thaw_buf

        debug "word = '$thawed_buf'"

        local value=$thawed_buf

        if is_define "$thawed_buf" ; then
            value=${DEFS[$thawed_buf]}

            # Only substitute whitespace delimited definition tokens.
            if [[ $c == [$WHITESPACE\;] ]] ; then
                info "substituting '$thawed_buf' with '$value'"
            else
                value=$thawed_buf
            fi
        fi

        push_buf "$value"

        return $RET_PROCHR_CONT
    fi
}

function process_char() {
    local c=$1 \
          pr_c=$2 \
          pushbuf=${3:-1} \
          ret=0 \
          fn=

    debug_l 2 "c='$c'"

    while true ; do
        fn="process_char_state_$st_name"

        debug_l 2 "entering $fn()"

        if $fn ; then
            ret=0
        else
            ret=$?
        fi

        debug_l 2 "left $fn(): ret = $ret"

        if (( ret != 0 )) ; then
            if (( ret & RET_PROCHR_PUSHBUF )) ; then
                push_buf "$c"
                pushbuf=0
            fi

            if (( ret & RET_PROCHR_POPSTATE )) ; then
                pop_state
            fi

            if (( ret & RET_PROCHR_SKIP )) ; then
                pushbuf=0
            fi

            if (( ret & RET_PROCHR_CONT )) ; then
                continue
            fi
        fi

        break
    done

    if (( pushbuf )) ; then
        push_buf "$c"
    fi
}

function iter_files() {
    local f=

    for f in "$@" ; do
        iter_file "$f"
    done
}

function iter_file() {
    local file=$1
    local filesize=$(wc -c <"$file")
    local fileoffset=0
    local c= pr_c=
    local lineno=1
    local charno=1
    local flushed=0

    local state_stack=()
    local state_stackbuf=()
    local state_stacklen=0

    local st_charno=1
    local st_buf=

    local st_name=$st_name_default
    local st=$st_default

    local heredoc_stack=( "<empty>" )
    local heredoc_stacktype=( "<empty>" )
    local heredoc_stacklen=0
    local hd_inline=0
    local hd_type="<empty>"
    local hd_buf=
    local hd="<empty>"

    local flushbuf=0
    local freezebuf=0
    local freezebuf_stack=()
    local freezebuf_stacklen=0
    local freezebuf_buf=
    local thawed_buf=

    local buf_ptr=0
    local buf=

    local getc_bufsize=4096
    local getc_buflen=0
    local getc_buf=
    local getc_offset=0
    local getc_eof=0

    push_state parsing

    while getc c ; do
        (( ++fileoffset ))

        if ! process_char "$c" "$pr_c" ; then
            break
        fi
        
        pr_c=$c

        if [[ $c == $LF ]] ; then
            (( ++lineno ))
            charno=1
        else
            (( ++charno ))
            (( ++st_charno ))
        fi
    done <"$file"

    if [[ $pr_c != $LF ]] ; then
      process_char '' "$c" 0 || true
    fi

    pop_state
    flush_buf 1

    info_progress

    if (( freezebuf )) ; then
        die "frozen buffer"
    elif (( st != eof )) ; then
        die "unexpected EOF"
    fi

    return 0
}

function getc() {
    if (( getc_offset == getc_buflen )) ; then
        debug "buffer empty - loading next $getc_bufsize bytes from file"

        if (( getc_eof )) ; then
            debug "already reached eof"
            return 1
        fi

        if ! IFS=$'\0' read -r -N $getc_bufsize getc_buf ; then
            getc_eof=1
        fi

        getc_buflen=${#getc_buf}
        getc_offset=0

        if (( getc_buflen == 0 )) ; then
            debug "nothing read from file - assuming eof"

            getc_eof=1
            return 1
        fi
    fi

    printf -v $1 "%c" "${getc_buf:$getc_offset:1}"

    debug_l 2 "'${!1}'"

    (( ++getc_offset ))
}

function usage() {
    cat <<USAGE
Usage: ${bashpp##*/} [options] file...
Options:
  -I dir                Add the directory defined by dir to the include path.

  -D name               Predefine name as a macro, with definition 1.

  -D name=definition    The contents of definition are tokenized and processed
                        as if they appeared during translation in a #define
                        directive.

                        If you are invoking the preprocessor from a shell or
                        shell-like program you may need to use the shell's
                        quoting syntax to protect characters such as spaces that
                        have a meaning in the shell syntax.

                        -D and -U options are processed in the order they are
                        given on the command line.

  -o file               Place the output into <file>

  -v --verbose          Verbose mode.

  -d --debug            Enable debugging information.

     --debug-level #    Set the debug level to #, default is $DEBUG.

     --debug-from #     Enable debugging information on and after line number #
                        in the source file.

     --debug-state statename[,statement...]
                        Enable debugging for a specific state or set of states.

     --max-errors #     Maximum number of errors permitted before stopping.  The
                        default is $ERROR_MAX.

Arguments:
    file                Specify an input file.  By default, input is read from
                        standard input.

Copyright (C) 2015 Craig Phillips.  All rights reserved.
USAGE
}

while (( $# > 0 )) ; do
    case $1 in
    (-I)
        add_include_dir "$2"
        shift
        ;;
    (-I*)
        add_include_dir "${1#-I}"
        ;;
    (-D)
        add_define "$2"
        shift
        ;;
    (-D*)
        add_define "${1#-D}"
        ;;
    (-U)
        remove_define "$2"
        shift
        ;;
    (-U*)
        remove_define "${1#-U}"
        ;;
    (-o)
        output=$(readlink -m "$2")
        shift
        ;;
    (-o*)
        output=$(readlink -m "${1#-o}")
        ;;
    (-v|--verbose)
        (( ++VERBOSE ))
        ;;
    (-d|--debug)
        (( ++DEBUG ))
        ;;
    (--debug-from)
        DEBUG_LINENO=$2
        shift

        set -- "$@" --debug
        ;;
    (--debug-from=*)
        DEBUG_LINENO=${1#*=}

        set -- "$@" --debug
        ;;
    (--debug-level)
        DEBUG=$2
        shift
        ;;
    (--debug-level=*)
        DEBUG=${1#*=}
        ;;
    (--debug-state)
        DEBUG_STATES+=" $2"
        shift
        ;;
    (--debug-state=*)
        DEBUG_STATES+=" ${1#*=}"
        ;;
    (--max-errors)
        ERROR_MAX=$2
        shift
        ;;
    (--max-errors=*)
        ERROR_MAX=${1#*=}
        ;;
    (-\?|--help)
        usage
        exit 0
        ;;
    (-*)
        die "illegal option: $1"
        ;;
    (*)
        files+=( "$1" )
        ;;
    esac
    shift
done

if (( ${#files[@]} == 0 )) ; then
    set -- /dev/stdin
fi

initialise

iter_files "${files[@]}" >"$output"

if (( errors != 0 )) ; then
    exit 1
fi
