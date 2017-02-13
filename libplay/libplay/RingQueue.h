//
//  RingQueue.h
//  CircularBuffer
//
//  Created by mac_dev on 16/1/13.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#ifndef __CircularBuffer__RingQueue__
#define __CircularBuffer__RingQueue__

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "pthread_auto_lock.h"

class RingQueue
{
public:
    RingQueue();
    ~RingQueue();
    
    size_t init (size_t capacity);
    size_t count();
    size_t capacity();
    size_t enqueue(const void* bytes, size_t length, double userData);
    size_t dequeue(void *dst, size_t length, double &userData);
    void cleanUp();
    void free ();
private:
    size_t beg_index_, end_index_, count_, capacity_;
    bool is_full_;
    char *data_;
    pthread_mutex_t mutex_;
};

#endif /* defined(__CircularBuffer__RingQueue__) */
