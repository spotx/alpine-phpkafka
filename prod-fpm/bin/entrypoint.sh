#!/bin/bash

# Enable bash's paranoid mode:
# set -E: Functions, subshells, and command substitutions inherit ERR traps
# set -e: Exit with error on command failure excepting pipes, ifs, whiles, ands, ors
# set -u: Exit with error on use of unset variables
# set -x: Print each command as its executed, including shell expansions
# set -o pipefail: Consider a pipeline to fail if ANY command in it fails
set -Eeuxo pipefail;

# this script will run php-fpm and nginx in the background
# stderr and stdout for those commands will automatically be forwarded
# wait will be used to catch if either app returns and exit the response
# trap will be used to forward signals

function quitsafe() {
    echo "QUITSAFE: forwarding signal"

    kill -s SIGTERM $PHP_PID
    kill -s SIGTERM $NGINX_PID

    # Exit with error code
    exit 1
}

# On any error or term signal, run the quitsafe function
trap 'quitsafe' ERR TERM QUIT INT KILL

# 1. Run php-fpm in the background
php-fpm -F &
PHP_PID=$!

# 2. Run nginx in the background
nginx -g 'daemon off;' &
NGINX_PID=$!


# give nginx & php-fpm a chance to start up
sleep 2

# 3. check that they started
if ! kill -0 $PHP_PID
then
    echo "[ERROR] PHP-FPM failed to start!"
    exit 2
fi
if ! kill -0 $NGINX_PID
then
    echo "[ERROR] nginx failed to start!"
    exit 2
fi

# 4. wait for one of them to stop
wait -n $PHP_PID -n $NGINX_PID

# 5. exit the response
exit $?
