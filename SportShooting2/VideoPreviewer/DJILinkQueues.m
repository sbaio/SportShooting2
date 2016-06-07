//
//  DJILinkQueues.m
//  DJI
//
//  Copyright (c) 2013. All rights reserved.
//

#import "DJILinkQueues.h"
#import <sys/time.h>
#import "DVFloatingWindow.h"

/**
 *  Node of the queue
 */
typedef struct{
    uint8_t *ptr;
    int size;
}DJILinkNode;

@interface DJILinkQueues()
{
    //node
    DJILinkNode *_node;
    int _size;
    int _count;
    int _head;
    int _tail;
    
    pthread_mutex_t _mutex;

    pthread_cond_t _cond;
}
@end

@implementation DJILinkQueues

- (DJILinkQueues *)initWithSize:(int)size{
    self = [super init];
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
    _head = 0;
    _tail = 0;
    _count = 0;
    _size = 0;
    _node = NULL;
    if(size<=0)return self;
    _size = size;
    _node = (DJILinkNode *)malloc(size*sizeof(DJILinkNode));
    return self;
}

- (void)clear{
    pthread_mutex_lock(&_mutex);
    int idx = 0;
    for(int i = 0;i<_count;i++){
        if(i+_head>=_size){
            idx = i+_head-_size;
        }
        else {
            idx = i+_head;
        }
        if(_node[idx].ptr!=NULL){
            free(_node[idx].ptr);
            _node[idx].ptr = NULL;
        }
        _node[idx].size = 0;
    }
    _head = 0;
    _tail = 0;
    _count = 0;
    pthread_mutex_unlock(&_mutex);
}


- (bool)push:(uint8_t *)buf length:(int)len{
    pthread_mutex_lock(&_mutex);
    if(len==0 || buf==NULL || [self isFull]){
        pthread_mutex_unlock(&_mutex);
        return NO;
    }
    _node[_tail].ptr = buf;
    _node[_tail].size = len;
    _tail++;
    if(_tail>=_size)_tail = 0;
    _count++;
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_mutex);
    return YES;
}

//It means the queue is empty if the return value is NULL )
- (uint8_t *)pull:(int *)len{
    
    pthread_mutex_lock(&_mutex);
    if(_count == 0)
    {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        
        struct timespec ts;
        ts.tv_sec = tv.tv_sec + 2;
        ts.tv_nsec = tv.tv_usec;
        pthread_cond_timedwait(&_cond, &_mutex, &ts);
        if(_count == 0)
        {
            *len = 0;
            pthread_mutex_unlock(&_mutex);
            return NULL;
        }
    }
    uint8_t *tmp = NULL;
    tmp = _node[_head].ptr;
    *len = _node[_head].size;
    _head++;
    if(_head>=_size)_head = 0;
    _count--;
    pthread_mutex_unlock(&_mutex);
    return tmp;
}

- (int)count{
    return _count;
}

- (int)size{
    return _size;
}

- (bool)isFull{
    if(_count==_size){
        return YES;
    }
    else{
        return NO;
    }
}
@end
