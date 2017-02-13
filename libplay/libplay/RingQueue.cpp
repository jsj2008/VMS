//
//  RingQueue.cpp
//  CircularBuffer
//
//  Created by mac_dev on 16/1/13.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#include "RingQueue.h"

static size_t header_length = sizeof(size_t);
static size_t user_info_lenght = sizeof(double);


RingQueue::RingQueue()
: beg_index_(0)
, end_index_(0)
, count_(0)
, capacity_(0)
, is_full_(false)
, data_(NULL)
{
    //初始化为递归锁
    pthread_mutex_init(&mutex_, NULL);
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&mutex_, &attr);
}

RingQueue::~RingQueue()
{
    free();
}

size_t RingQueue::init (size_t capacity)
{
    pthread_auto_lock lk(&mutex_);
    
    if (data_) return 0;
    if (capacity == 0) return 0;
    
    capacity_ = capacity;
    data_ = new char[capacity];
    memset(data_, 0, capacity);
    
    cleanUp();
    
    return capacity_;
}

size_t RingQueue::count()
{
    pthread_auto_lock lk(&mutex_);
    
    if (!is_full_ && (beg_index_ == end_index_)) {
        return 0;//队列为空
    }
    
    return count_;
}

size_t RingQueue::capacity()
{
    pthread_auto_lock lk(&mutex_);
    
    return capacity_;
}

size_t RingQueue::enqueue(const void* bytes, size_t length, double userData)
{
    pthread_auto_lock lk(&mutex_);
    
    if (length == 0) return 0;
    if (!data_) return 0;
    if (!bytes) return 0;
    if (is_full_) return 0;
    
    
    size_t capacity = capacity_;
    size_t length_to_write = header_length + user_info_lenght + length;
    size_t ret = 0;
    
    //断言队列没有越界
    assert(capacity >= end_index_);
    assert(capacity >= beg_index_);
    
    
    char *ptr = data_ + end_index_;
    char *ptr_header = ptr;
    char *ptr_user_data = ptr + header_length;
    char *ptr_buffer = ptr + header_length + user_info_lenght;
    
    if (beg_index_ <= end_index_) {
        //考虑顶部还有剩余空间
        if (length_to_write <= capacity - end_index_) {
            //写内存
            *(size_t*)ptr_header = header_length + user_info_lenght + length;
            *(double *)ptr_user_data = userData;
            memcpy(ptr_buffer, bytes, length);
            
            //更新指针索引
            end_index_ += length_to_write;
            //更新size
            count_++;
            ret = length;
        } else {
            //考虑换一边,从底部存储
            //将剩余部分至零，标记为无效区域
            size_t invalid_length = capacity - end_index_;
            memset(ptr_header, 0, invalid_length);
            
            
            if (length_to_write <= beg_index_) {
                ptr = data_;
                ptr_header = ptr;
                ptr_user_data = ptr_header + header_length;
                ptr_buffer = ptr_user_data + user_info_lenght;
                
                //写内存
                *(size_t*)ptr_header = header_length + user_info_lenght + length;
                *(double *)ptr_user_data = userData;
                memcpy(ptr_buffer, bytes, length);
                
                //更新指针索引
                end_index_ = length_to_write;
                //更新size
                count_++;
                ret = length;
            }
        }
    } else if (length_to_write <= beg_index_ - end_index_) {
        //写内存
        *(size_t*)ptr_header = header_length + user_info_lenght + length;
        *(double *)ptr_user_data = userData;
        memcpy(ptr_buffer, bytes, length);
        
        //更新指针索引
        end_index_ += length_to_write;
        //更新size
        count_++;
        ret = length;
    }
    
    //检查是否满了
    is_full_ = (beg_index_ == end_index_);

    return ret;
}

size_t RingQueue::dequeue(void *dst, size_t length, double &userData)
{
    pthread_auto_lock lk(&mutex_);
    
    if (length == 0) return 0;
    if (!data_) return 0;
    if (!dst) return 0;
    
    if (!is_full_ && (beg_index_ == end_index_)) {
        count_ = 0;
        return 0;//队列为空
    }
    
    size_t capacity = capacity_;
    char *ptr = data_ + beg_index_;
    char *ptr_header = ptr;
    
    //此处断言队列索引没有越界.
    assert(beg_index_ <= capacity);
    assert(end_index_ <= capacity);
    assert(count_ > 0);
    
    size_t length_to_read = 0;
    
    if (capacity - beg_index_ >= header_length) {
        //解析数据头
        length_to_read = *((size_t *)ptr_header);
    }
    
    //检查是否需要换一头进行读取
    if (length_to_read == 0) {
        ptr = data_;
        ptr_header = ptr;
        
        //再次解析数据头
        length_to_read = *((size_t *)ptr_header);
    }
    
    //此处断言必定有数据读取(函数入口已经对队列判空)
    assert(length_to_read > 0);
    //断言要读取的长度不越界
    assert(length_to_read <= capacity);
    //断言数据区长度不为0
    assert(length_to_read > (header_length + user_info_lenght));
    
    
    char *ptr_user_info = ptr_header + header_length;
    char *ptr_buffer = ptr_header + header_length + user_info_lenght;
    size_t buffer_length = length_to_read - (header_length + user_info_lenght);
    
    if (length >= buffer_length) {
        userData = *((double *)ptr_user_info);
        memcpy(dst, ptr_buffer, buffer_length);
        
        //更新指针索引
        beg_index_ = ptr_header + length_to_read - data_;
        
        //判断队列是否已经为空
        if (beg_index_ == end_index_) {
            beg_index_ = end_index_ = 0;
        }
        
        //取消队列已满标志
        is_full_ = false;
        
        //更新size
        count_--;
        return buffer_length;
    }
    
    return 0;
}

void RingQueue::cleanUp()
{
    pthread_auto_lock lk(&mutex_);
    
    beg_index_ = end_index_ = 0;
    is_full_ = 0;
}

void RingQueue::free()
{
    pthread_auto_lock lk(&mutex_);
    
    if (!data_) return;
    delete [] data_;
    
    data_ = NULL;
    cleanUp();
}
