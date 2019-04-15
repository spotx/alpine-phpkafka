#!/bin/bash

# Enable bash's paranoid mode:
# set -E: Functions, subshells, and command substitutions inherit ERR traps
# set -e: Exit with error on command failure excepting pipes, ifs, whiles, ands, ors
# set -u: Exit with error on use of unset variables
# set -x: Print each command as its executed, including shell expansions
# set -o pipefail: Consider a pipeline to fail if ANY command in it fails
set -Eeuxo pipefail;

# this script will run a PHP command in the background.
# stderr and stdout for those commands will automatically be forwarded
# wait will be used to catch if either app returns and exit the response
# trap will be used to forward signals

function quitsafe() {
    echo "QUITSAFE: forwarding signal"

    kill -s SIGTERM $PHP_PID

    # Exit with error code
    exit 1
}

# On any error or term signal, run the quitsafe function
trap 'quitsafe' ERR TERM QUIT INT KILL

# 1. Run PHP command in the background
php $1 &
PHP_PID=$!

# give the PHP command a chance to start up
sleep 2

# 3. check that they started
if ! kill -0 $PHP_PID
then
    echo "[ERROR] PHP $1 failed to start!"
    exit 2
fi

# 4. wait for one of them to stop
wait -n $PHP_PID

# 5. exit the response
exit $?
