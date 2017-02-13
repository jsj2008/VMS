//
//  Device.h
//  VMS
//
//  Created by mac_dev on 15/7/8.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"
#import "Channel.h"

@interface CDevice : TreeNode

//CDevice property
@property (nonatomic,assign) int type;
@property (nonatomic,copy) NSString *ip;
@property (nonatomic,assign) int port;
@property (nonatomic,copy) NSString *userName;
@property (nonatomic,copy) NSString *userPsw;
@property (nonatomic,assign) int rtspPort;
@property (nonatomic,copy) NSString *macAddress;
@property (nonatomic,copy) NSString *serialNumber;
@property (nonatomic,assign) int decoderType;
@property (nonatomic,assign) int channelCount;
@property (nonatomic,weak) Group *group;
//state property
@property (assign,getter=isOnline) BOOL online;

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
                 Group :(Group *)group;
@end
