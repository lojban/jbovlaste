#!/bin/bash

find /tmp/jbovlaste_export -type f -mtime -2 | xargs -r rm
find /tmp/jbovlaste_export -type d -mtime -2 | xargs -r rmdir --ignore-fail-on-non-empty
