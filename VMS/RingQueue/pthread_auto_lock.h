//
//  AutoPThreadMutex.h
//  FoscamNetSDK
//
//  Created by mac_dev on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#ifndef __FoscamNetSDK__AutoPThreadMutex__
#define __FoscamNetSDK__AutoPThreadMutex__

#include <stdio.h>
#include <pthread.h>

class pthread_auto_lock
{
public:
    pthread_auto_lock(pthread_mutex_t *mutex);
    ~pthread_auto_lock();
private:
    pthread_mutex_t *_mutex;
};

#endif /* defined(__FoscamNetSDK__AutoPThreadMutex__) */
