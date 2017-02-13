//
//  AVSourceServerCppWrap.h
//  VMS
//
//  Created by mac_dev on 15/11/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../WebPlugin/WebPlugin/TransferSvr/AvSource.h"
#import "AVSourceServer.h"

class AVSourceServerCppWrap : public AvSource
{
public:
    AVSourceServerCppWrap(AvSourceCallBack *cb);
    virtual ~AVSourceServerCppWrap(void);
    virtual int open_video(int channelID);
    virtual void close_video(int channelID) ;
    virtual int open_audio(int channelID);
    virtual void close_audio(int channelID);
    virtual void ptz_controll(int channelID, int type,	int param1,	int param2,	int param3,	int param4,	const char* param5);
    
    const AVSourceServer *server();
private:

    AVSourceServer *_server;
};


