#! /bin/sh
#
# Copyright (c) 2007 Urbacon Ltd.
#
# System startup script for the RubyCAS-Server
#
# Instructions:
#   1. Rename this file to 'rubycas-server'
#   2. Copy it to your '/etc/init.d' directory
#   3. chmod +x /etc/init.d/rubycas-server
#
# chkconfig - 85 15
# description: Provides single-sign-on authentication for web applications.
#
### BEGIN INIT INFO
# Provides: rubycas-server
# Required-Start: $syslog
# Should-Start:
# Required-Stop:  $syslog
# Should-Stop:
# Default-Start:  3 5
# Default-Stop:   0 1 2 6
# Description:    Start the RubyCAS-Server
### END INIT INFO

CASSERVER_CTL=rubycas-server-ctl

# Gracefully exit if the controller is missing.
which $CASSERVER_CTL > /dev/null || exit 0

# Source function library.
if [ -r /etc/init.d/functions ]; then
 source /etc/init.d/functions
 start() {
     echo -n "Starting rubycas-server: "

     $CASSERVER_CTL start
     RETVAL=$?
     echo
     return $RETVAL
 }

 stop() {
     echo -n "Starting rubycas-server: "

     $CASSERVER_CTL stop
     RETVAL=$?
     echo
     return $RETVAL
 }

 # See how we were called.
 case "$1" in
   start)
         start
         ;;
   stop)
         stop
         ;;
   restart)
         stop
         sleep 2	
         start
         ;;
   *)
 	echo "Usage: $0 {start|stop|restart}"
 	exit 1
 esac

 exit $RETVAL
elif [ -r /etc/rc.status ]; then
 source /etc/rc.status
 rc_reset
 case "$1" in
     start)
         $CASSERVER_CTL start
         rc_status -v
         ;;
     stop)
         $CASSERVER_CTL stop
         rc_status -v
         ;;
     restart)
         $0 stop
         $0 start
         rc_status
         ;;
     status)
         $CASSERVER_CTL status
         rc_status -v
         ;;
     *)
         echo "Usage: $0 {start|stop|status|restart}"
         exit 1
         ;;
 esac
fi

rc_exit
