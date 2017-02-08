//
//  commons.h
//  
//
//  Created by mac_dev on 16/5/11.
//
//

#ifndef ____commons__
#define ____commons__

#include <stdio.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <stdlib.h>

double gettimeofday_ext();
void timeSpecFromNow(long waitMSecs,timespec *absTime);
#endif /* defined(____commons__) */
