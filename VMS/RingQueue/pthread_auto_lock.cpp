//
//  AutoPThreadMutex.cpp
//  FoscamNetSDK
//
//  Created by mac_dev on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#include "pthread_auto_lock.h"

pthread_auto_lock::pthread_auto_lock(pthread_mutex_t *mutex)
{
    if (mutex) {
        _mutex = mutex;
        pthread_mutex_lock(mutex);
    }
}

pthread_auto_lock::~pthread_auto_lock(void)
{
    if (_mutex) {
        pthread_mutex_unlock(_mutex);
    }
}
    