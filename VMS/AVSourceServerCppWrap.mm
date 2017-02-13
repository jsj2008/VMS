//
//  AVSourceServerCppWrap.m
//  VMS
//
//  Created by mac_dev on 15/11/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AVSourceServerCppWrap.h"


AVSourceServerCppWrap::AVSourceServerCppWrap(AvSourceCallBack *cb) : AvSource(cb)
{
    _server = [[AVSourceServer alloc] init];
    _server.delegate = cb;
}


AVSourceServerCppWrap::~AVSourceServerCppWrap(void)
{
    _server = nil;
}

int AVSourceServerCppWrap::open_video(int channelID)
{
    if (_server)
        return [_server openVideo:channelID];
    
    return -1;
}

void AVSourceServerCppWrap::close_video(int channelID)
{
    [_server closeVideo:channelID];
}

int AVSourceServerCppWrap::open_audio(int channelID)
{
    if (_server)
        return [_server openAudio:channelID];
    
    return -1;
}

void AVSourceServerCppWrap::close_audio(int channelID)
{
    [_server closeAudio:channelID];
}

void AVSourceServerCppWrap::ptz_controll(int channelID,
                                         int type,
                                         int param1,
                                         int param2,
                                         int param3,
                                         int param4,
                                         const char* param5)
{
    [_server ptzControll:channelID
                    type:type
                  param1:param1
                  param2:param2
                  param3:param3
                  param4:param4
                  param5:param5];
}

const AVSourceServer *AVSourceServerCppWrap::server()
{
    return _server;
}
