#!/bin/bash

groupadd -g 3000 afterlogic
useradd afterlogic -u 3000 -d /opt/afterlogic -g afterlogic
