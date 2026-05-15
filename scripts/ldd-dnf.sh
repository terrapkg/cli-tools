#!/usr/bin/env bash

ldd $1 | awk '{ if ($3 != "") { print "\"*" $3 "\""}}' | xargs dnf provides
