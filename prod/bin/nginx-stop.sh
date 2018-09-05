#!/bin/bash
set -e

if [ -n "$(pgrep nginx)" -a -f /var/run/nginx.pid ]; then
  PID=$( cat /var/run/nginx.pid )

  # Gracefully shutdown nginx
  kill -QUIT $PID

  # Wait for nginx to stop
  while [ -d "/proc/$PID" -a -f /var/run/nginx.pid ]; do
    sleep 1
  done

else
  echo "nginx is not running."
  exit 1
fi
