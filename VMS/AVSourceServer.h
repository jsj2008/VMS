//
//  AVSourceServer.h
//  VMS
//
//  Created by mac_dev on 15/11/12.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DispatchCenter.h"
#import "VMSDatabase.h"
#import "../WebPlugin/WebPlugin/TransferSvr/AvSource.h"




@interface AVSourceServer : NSObject<DispatchProtocal>

@property (nonatomic,assign) AvSourceCallBack *delegate;

- (instancetype)init;
- (int)openVideo :(int)chnId;
- (void)closeVideo :(int)chnId;
- (int)openAudio :(int)chnId;
- (void)closeAudio :(int)chnId;
- (void)ptzControll :(int)chnId
               type :(int)type
             param1 :(int)param1
             param2 :(int)param2
             param3 :(int)param3
             param4 :(int)param4
             param5 :(const char *)param5;
@end
