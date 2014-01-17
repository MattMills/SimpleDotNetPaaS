#!/bin/bash

# SimpleDotNetPaaS
#
# Copyright (C) 2014  Matt Mills
#
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
# along with this program.  If not, see [http://www.gnu.org/licenses/].

if [ $# -lt 3 ] ; then
	echo "FAIL No arguments supplied"
	exit 1
fi
SITENAME=$1
SERVERNAME=$2
SERVERADDR=$3

SITECONFIG="	server $SERVERNAME $SERVERADDR cookie $SITENAME-$SERVERNAME check inter 2000 rise 2 fall 5"

if [ ! -f /etc/haproxy/conf.d/02-be-asptest_$SITENAME.conf ] ; then
	echo "FAIL site not provisioned"
	exit 1
fi
if grep -Fq "server $SERVERNAME" /etc/haproxy/conf.d/02-be-asptest_$SITENAME.conf ; then
        echo "FAIL server already provisioned"
        exit 2
fi

echo "$SITECONFIG" >> /etc/haproxy/conf.d/02-be-asptest_$SITENAME.conf
echo "PASS server provisioned"
