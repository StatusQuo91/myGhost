#!/bin/sh

if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
    GHOST_START="HOME=/opt/bitnami/apps/ghost NODE_ENV=production /opt/bitnami/nodejs/bin/node /opt/bitnami/nodejs/bin/forever start index.js"
    GHOST_STOP="HOME=/opt/bitnami/apps/ghost NODE_ENV=production /opt/bitnami/nodejs/bin/node /opt/bitnami/nodejs/bin/forever stop index.js"
else
    GHOST_START="/opt/bitnami/nodejs/bin/node /opt/bitnami/nodejs/bin/forever start index.js"
    GHOST_STOP="/opt/bitnami/nodejs/bin/node /opt/bitnami/nodejs/bin/forever stop index.js"
fi

NODE_ENV=production
export NODE_ENV
GHOST_PROGRAM=/opt/bitnami/apps/ghost/htdocs/index.js
GHOST_PID=""
GHOST_STATUS=""
ERROR=0

is_service_running() {
    GHOST_PID=`COLUMNS=400 ps ax | grep "$1" | grep -v "grep" | awk '{print $1}' 2>&1`
    if [ $GHOST_PID ] ; then
        RUNNING=1
    else
        RUNNING=0
    fi
    return $RUNNING
}

is_ghost_running() {
    is_service_running "$GHOST_PROGRAM"
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        GHOST_STATUS="Ghost not running"
    else
        GHOST_STATUS="Ghost already running"
    fi
    return $RUNNING
}

start_ghost() {
    is_ghost_running
    RUNNING=$?
    if [ $RUNNING -eq 1  ]; then
        echo "$0 $ARG: Ghost (pid $GHOST_PID) already running"
        exit
    else 
	cd /opt/bitnami/apps/ghost/htdocs
	if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
            su daemon -s /bin/sh -c "$GHOST_START"
	else
            $GHOST_START
        fi
    fi
    sleep 3
    is_ghost_running
    RUNNING=$?
    COUNTER=30
    while [ $RUNNING -ne 0 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 1
        is_ghost_running
        RUNNING=$?
    done
    if [ $RUNNING -eq 0 ]; then
        ERROR=1
    fi
    if [ $ERROR -eq 0 ]; then
	echo "$0 $ARG: Ghost started"
    else
	echo "$0 $ARG: Ghost could not be started"
	ERROR=3
    fi

}

stop_ghost() {
    NO_EXIT_ON_ERROR=$1
    is_ghost_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $GHOST_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi

    cd /opt/bitnami/apps/ghost/htdocs	
    if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
        su daemon -s /bin/sh -c "$GHOST_STOP"
    else
        $GHOST_STOP
    fi

    is_ghost_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: Ghost stopped"
        else
            echo "$0 $ARG: Ghost could not be stopped"
            ERROR=4
    fi
}

if [ "x$1" = "xstart" ]; then
    start_ghost
elif [ "x$1" = "xstop" ]; then
    stop_ghost
elif [ "x$1" = "xstatus" ]; then
    is_ghost_running
    echo "$GHOST_STATUS"
fi

exit $ERROR
