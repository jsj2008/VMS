//
//  Device.m
//  VMS
//
//  Created by mac_dev on 15/7/8.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "CDevice.h"

@interface CDevice()

@end

@implementation CDevice

- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
                  type :(int)type
                    ip :(NSString *)ip
                  port :(int)port
              userName :(NSString *)userName
               userPsw :(NSString *)userPsw
              rtspPort :(int)rtspPort
            macAddress :(NSString *)macAddress
          serialNumber :(NSString *)serialNumber
          decorderType :(int)decoderType
          channelCount :(int)channelCount
                  Group:(Group *)group
{
    if (self = [super initWithUniqueId:uniqueId name:name]) {
        self.type = type;
        self.ip = ip;
        self.port = port;
        self.userName = userName;
        self.userPsw = userPsw;
        self.rtspPort = rtspPort;
        self.macAddress = macAddress;
        self.serialNumber = serialNumber;
        self.decoderType = decoderType;
        self.channelCount = channelCount;
        self.group = group;
    }
    
    return self;
}


- (void)dealloc
{
    //NSLog(@"Device %ld dealloc",self.uniqueId);
}

@end
