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

if [ $# -lt 1 ] ; then
	echo "FAIL No arguments supplied"
	exit 1
fi
SITENAME="$1"

if [ ! -f /etc/haproxy/conf.d/02-be-asptest_$SITENAME.conf ] ; then
	echo "FAIL site not provisioned"
	exit 1
fi

rm -f /etc/haproxy/conf.d/02-be-asptest_$SITENAME.conf
grep -Fv "host_$SERVERNAME" /etc/haproxy/conf.d/01-fe-asptest.conf > /etc/haproxy/conf.d/01-fe-asptest.conf.new
rm -f /etc/haproxy/conf.d/01-fe-asptest.conf
mv /etc/haproxy/conf.d/01-fe-asptest.conf.new /etc/haproxy/conf.d/01-fe-asptest.conf
echo "PASS site deprovisioned"
