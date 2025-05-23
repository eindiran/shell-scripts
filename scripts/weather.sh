#!/usr/bin/env zsh
#===============================================================================
#
#          FILE: weather.sh
#
#         USAGE: weather.sh [-h] [-V] [-i | -m | -M] [-t] [-o] [-v <VIEW>] [-f <FORMAT>] [-r] [-S] <LOCATION>
#
#      EXAMPLES:
#                 weather.sh -h -> Print the usage and exit.
#                 weather.sh -i "San Francisco"  -> Print weather info
#                     from wttr.in for San Francisco in Imperial units.
#                     Note that the quotes around LOCATION are not required.
#                 weather.sh -r New York  -> Print the weather for NYC, using
#                     metric units and rich (V2) formatting.
#                 weather.sh -S -M "Los Angeles" -> Get weather for LA using
#                     HTTPS and metric, with the windspeed in m/s.
#                 weather.sh -f 2 "Chicago" -> Print one-line of output in format
#                     #2 for Chicago.
#                 weather.sh -o "San Diego" -> One line output for San Diego. Equivalent
#                     to the -f 3 option.
#                 weather.sh -t London -> Show the weather for London in plain text,
#                     no ANSI color sequences will be used.
#                 weather.sh -v 0 Beijing -> Show results using view option '0'. Default: 2
#                 weather.sh -v n Miami -> Output results for Miami in "narrow" mode
#
#   DESCRIPTION: Fetch the weather from wttr.in using a simple CLI to handle
#                formatting the URL.
#
#       OPTIONS:
#                  -h: Print the usage and exit
#                  -V: Verbose mode: print the wttr.in URL
#                  -i: Use Imperial units
#                  -m: Use metric units (default)
#                  -M: Show windspeed in meters/sec
#                  -r: Show data-rich V2 format
#                  -S: Use HTTPS (default: http)
#                  -f: Specify a one-line format number (1 - 4)
#                  -o: One-line output only
#                  -t: Plain text mode; disable ANSI colors
#                  -v: Set the view mode (0, 1, 2, A d, F, n, q, Q, T)
#
#  REQUIREMENTS: curl
#         NOTES: ---
#        AUTHOR: Elliott Indiran <elliott.indiran@protonmail.com>
#       CREATED: 2024-06-30
#      REVISION: 1.0.0
#
#===============================================================================

set -Eeuo pipefail

usage() {
    cat <<EOF
      USAGE: weather.sh [-h] [-V] [-i | -m | -M] [-v <VIEW>] [-f <FORMAT>] [-o] [-t] [-r] [-S] <LOCATION>

DESCRIPTION: Fetch the weather from wttr.in using a simple CLI to handle
             formatting the URL.

    OPTIONS:
             -h: Print the usage and exit
             -V: Verbose mode: print the wttr.in URL
             -i: Use Imperial units
             -m: Use metric units (default)
             -M: Show windspeed in meters/sec
             -r: Show data-rich V2 format.
             -S: Use HTTPS (default: http)
             -f: Specify a one-line format number (1 - 4)
             -o: One-line output only
             -t: plain text mode; disable ANSI colors
             -v: Set the view mode (0, 1, 2, A d, F, n, q, Q, T)

   EXAMPLES:
              weather.sh -h -> Print the usage and exit.
              weather.sh -i "San Francisco"  -> Print weather info
                  from wttr.in for San Francisco in Imperial units.
                  Note that the quotes around LOCATION are not required.
              weather.sh -r New York  -> Print the weather for NYC, using
                  metric units and rich (V2) formatting.
              weather.sh -S -M "Los Angeles" -> Get weather for LA using
                  HTTPS and metric, with the windspeed in m/s.
              weather.sh -f 2 "Chicago" -> Print one-line of output in format
                  #2 for Chicago.
              weather.sh -o "San Diego" -> One line output for San Diego. Equivalent
                  to the -f 3 option.
              weather.sh -t London -> Show the weather for London in plain text,
                  no ANSI color sequences will be used.
              weather.sh -v 0 Beijing -> Show results using view option '0'. Default: 2
              weather.sh -v n Miami -> Output results for Miami in "narrow" mode

       NOTE: Requires curl
EOF
    exit "${1}"
}

base_url="wttr.in"
url_prefix="http"
units_flavor="m"
rich_data_format=false
one_line=false
format_number=3
view_mode=""
verbose=false

declare -A view_modes=([0]=1 [1]=1 [2]=1 [A]=1 [d]=1 [F]=1 [n]=1 [q]=1 [Q]=1 [T]=1)

while getopts "himMSrtoVf:v:" option; do
    case "${option}" in
        h)
            usage 0
            ;;
        i)
            units_flavor="u"
            ;;
        m)
            units_flavor="m"
            ;;
        M)
            units_flavor="M"
            ;;
        r)
            rich_data_format=true
            ;;
        S)
            url_prefix="https"
            ;;
        t)
            view_mode="T"
            ;;
        o)
            one_line=true
            ;;
        f)
            format_number="${OPTARG}"
            one_line=true
            ;;
        v)
            view_mode="${OPTARG}"
            ;;
        V)
            verbose=true
            ;;
        *)
            printf "Unknown option %s\n" "${option}"
            usage 1
            ;;
    esac
done
shift $((OPTIND - 1))
location=$@
if [[ -z "${location}" ]]; then
    echo "You must specify a location!"
    exit 2
fi
location="${location/ /+}"

if [[ -n "${view_mode}" ]] && [[ -z "${view_modes[$view_mode]+x}" ]]; then
    echo "Unknown view mode: ${view_mode}"
    exit 2
fi

local wttrin_url
if [[ "${one_line}" == true ]]; then
    # In one-line mode, ie with the -o or -f flags, don't use head/tail
    # to strip of anything.
    wttrin_url="${url_prefix}://${base_url}/${location}?${view_mode}${units_flavor}&format=${format_number}"
    if [[ "${verbose}" == true ]]; then
        echo "${wttrin_url}"
    fi
    curl "${wttrin_url}" 2> /dev/null
elif [[ "${rich_data_format}" == true ]]; then
    wttrin_url="${url_prefix}://v2d.${base_url}/${location}?${view_mode}${units_flavor}"
    if [[ "${verbose}" == true ]]; then
        echo "${wttrin_url}"
    fi
    echo "┌────────────────────────────────────────────────────────────────────────┐"
    # ^ replace header
    curl "${wttrin_url}" 2> /dev/null | tail -n +2 | head -n -2
elif [[ "${view_mode}" == "0" ]]; then
    wttrin_url="${url_prefix}://${base_url}/${location}?${view_mode}${units_flavor}"
    # In view-mode 0, dont use head (with negative value, as with one-line mode)
    # as there is no header. Do use tail for the header:
    if [[ "${verbose}" == true ]]; then
        echo "${wttrin_url}"
    fi
    curl "${wttrin_url}" 2> /dev/null | tail -n +2
else
    wttrin_url="${url_prefix}://${base_url}/${location}?${view_mode}${units_flavor}"
    if [[ "${verbose}" == true ]]; then
        echo "${wttrin_url}"
    fi
    curl "${wttrin_url}" 2> /dev/null | tail -n +2 | head -n -2
fi
