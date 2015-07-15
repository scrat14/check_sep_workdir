#!/usr/bin/env bash

#######################################################
#                                                     #
#  Name:    check_sep_workdir                         #
#                                                     #
#  Version: 1.0                                       #
#  Created: 2015-07-15                                #
#  License: GPL - http://www.gnu.org/licenses         #
#  Copyright: (c)2015 Rene Koch                       #
#  Author:  Rene Koch <rkoch@rk-it.at>                #
#  URL: https://github.com/scrat14/check_sep_workdir  #
#                                                     #
#######################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Changelog:
# * 1.0.0 - Wed Jul 15 2015 - Rene Koch <rkoch@rk-it.at>
# - This is the first release of new plugin check_sep_workdir

# Create performance data
# 0 ... disabled
# 1 ... enabled
PERFDATA=1

# Variables
PROG="check_sep_workdir"
VERSION="1.0"

# Icinga/Nagios status codes
STATUS_WARNING=1
STATUS_CRITICAL=2
STATUS_UNKNOWN=3

# Default warning and critical values
WARN=40
CRIT=20


# function print_usage()
print_usage(){
  echo "Usage: ${0} [-w <warn>] [-c <critical>] [-V]"
}


# function print_help()
print_help(){
  echo ""
  echo "SEP free space in workdir check for Icinga/Nagios version ${VERSION}"
  echo "(c)2015 - Rene Koch <rkoch@rk-it.at>"
  echo ""
  echo ""
  print_usage
  cat <<EOT

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -w, --warning=RANGE
    Generate warning state if metric is outside this range
 -c, --critical=RANGE
    Generate warning state if metric is outside this range

Send email to rkoch@rk-it.at if you have questions regarding use
of this software. To sumbit patches of suggest improvements, send
email to rkoch@rk-it.at
EOT

exit ${STATUS_UNKNOWN}

}


# function print_version()
print_version(){
  echo "${PROG} ${VERSION}"
  exit ${STATUS_UNKNOWN}
}


# The main function starts here

# Parse command line options
while test -n "$1"; do
  
  case "$1" in
    -h | --help)
      print_help
      ;;
    -V | --version)
      print_version
      ;;
    -w | --warning)
      WARN=${2}
      shift
      ;;
    -c | --critical)
      CRIT=${2}
      shift
      ;;
    *)
      echo "Unknown argument: ${1}"
      print_usage
      exit ${STATUS_UNKNOWN}
      ;;
  esac
  shift
      
done


# Check if bc is installed
which bc >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "SEP Workdir UNKNOWN: bc not found!"
  exit ${STATUS_UNKNOWN}
fi

# Check if zarafa-admin is installed
which zarafa-admin >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "SEP Workdir UNKNOWN: zarafa-admin not found!"
  exit ${STATUS_UNKNOWN}
fi


# Check if warning is smaller then critical
if [ ${WARN} -le ${CRIT} ]; then
  echo "SEP Workdir UNKNOWN: Warning value needs to be larger then critical value!"
  exit ${STATUS_UNKNOWN}
fi


# Get free space in SEP workdir
SEP_FREE=`df -Tk /var/opt/sesam/var/work/ | tail -1 | awk '{ print $(NF-2) }'`

# Get biggest Zarafa mailbox
ZARAFA_MBOX=`for user in $(zarafa-admin -l | tail -n +5 | awk '{ print $1 }' | head -n -1); do bc <<< $(zarafa-admin --detail $user | grep 'Current store size' | awk '{ print $4 }')*1024; done | sort -n | tail -1`

if [ `bc <<< ${ZARAFA_MBOX}*1.${CRIT} | awk -F. '{ print $1  }'` -gt ${SEP_FREE} ]; then
  echo "SEP Workdir CRITICAL: ${SEP_FREE}KB free, biggest mailbox is ${ZARAFA_MBOX}KB"
  exit ${STATUS_CRITICAL}
elif [ `bc <<< ${ZARAFA_MBOX}*1.${WARN} | awk -F. '{ print $1  }'` -gt ${SEP_FREE} ]; then
  echo "SEP Workdir WARNING: ${SEP_FREE}KB free, biggest mailbox is ${ZARAFA_MBOX}KB"
  exit ${STATUS_WARNING}
else
  echo "SEP Workdir OK: ${SEP_FREE}KB free, biggest mailbox is ${ZARAFA_MBOX}KB"
  exit ${STATUS_OK}
fi


exit ${STATUS}

