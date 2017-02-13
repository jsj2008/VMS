#!/bin/sh

#  BuildScript.command
#  TasksProject
#
#  Created by Andy on 3/23/13.
#  Copyright (c) 2013 Ray Wenderlich. All rights reserved.


SERVICE='VMS.app'

if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
echo "$SERVICE is running"
exit -1
else
echo "$SERVICE is not running"
#rm -r ~/Library/Containers/com.foscam.vms
#rm -r ~/Library/Containers/com.foscam.vms.helper
fi
