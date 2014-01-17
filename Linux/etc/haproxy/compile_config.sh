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

now=$(date +"%s_%N")

cd /etc/haproxy
cat conf.d/*.conf > haproxy.cfg.$now

mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.last && ln -s /etc/haproxy/haproxy.cfg.$now /etc/haproxy/haproxy.cfg
haproxy -f /etc/haproxy/haproxy.cfg -c

rc=$?
if [[ $rc != 0 ]] ; then
	echo "FAIL CONFIG_UPDATE_FAILED"
	rm -f /etc/haproxy/haproxy.cfg
	mv /etc/haproxy/haproxy.cfg.last /etc/haproxy/haproxy.cfg
	exit $rc
else
	echo "PASS CONFIG_UPDATE_SUCCESS"
	rm -f /etc/haproxy/haproxy.cfg.last
	#rm -f /etc/haproxy/haproxy.cfg.$now
	exit 0
fi

