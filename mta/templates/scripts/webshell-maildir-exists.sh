#!/bin/bash
##
# Afterlogic Mailsuite
# script check user home maildir exists
# (c) Afterlogic Corp. 2009-2025
##

set -e
mail_home="/opt/afterlogic/data"

if [ -d "${mail_home}/$1/$2" ]; then
  echo "EXISTS"
  exit 0
else
  echo "NOT_EXISTS"
  exit 1
fi