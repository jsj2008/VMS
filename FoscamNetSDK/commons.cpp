//
//  commons.c
//  
//
//  Created by mac_dev on 16/5/11.
//
//

#include "commons.h"
double time_2_dbl(struct timeval time_value)
{
    double new_time = 0.0;
    new_time = (double) (time_value.tv_usec) ;
    new_time /= 1000000.0;
    new_time += (double)time_value.tv_sec;
    //printf("the time.. %f\n", new_time);
    return(new_time);
} /* end time_2_dbl() */

double gettimeofday_ext()
{
    struct timeb timebuffer;
    struct timeval tp;
    ftime( &timebuffer );
    tp.tv_sec  = timebuffer.time;
    tp.tv_usec = timebuffer.millitm * 1000;
    
    return time_2_dbl(tp);
}

void timeSpecFromNow(long waitMSecs,timespec *absTime)
{
    struct timeval now;
    timespec nowTime;
    gettimeofday(&now, NULL);
    
    
    TIMEVAL_TO_TIMESPEC(&now, &nowTime);
    long nsecs = nowTime.tv_nsec + waitMSecs * 1000000;
    long secs = nsecs / 1000000000;
    
    absTime->tv_sec = nowTime.tv_sec + secs;
    absTime->tv_nsec = nsecs - secs * 1000000000;
}