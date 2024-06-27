#!/bin/bash

/opt/afterlogic/bin/eximstats -html=/opt/afterlogic/html/p7/stat/current_week/eximstats.html -charts -chartdir /opt/afterlogic/html/p7/stat/current_week/eximstats /opt/afterlogic/var/log/exim/eximmain.log
