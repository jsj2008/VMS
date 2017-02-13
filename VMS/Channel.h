//
//  Channel.h
//  VMS
//
//  Created by mac_dev on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "TreeNode.h"

@class CDevice;
@interface Channel : TreeNode<NSCopying,NSPasteboardWriting>

//Channel property
@property (nonatomic,assign) int type;
@property (nonatomic,assign) int logicId;
@property (nonatomic,assign) int unused1;
@property (nonatomic,assign) int unused2;
@property (nonatomic,copy) NSString *mapX;
@property (nonatomic,copy) NSString *mapY;
@property (nonatomic,assign) int patrolGroupId;
@property (nonatomic,weak) CDevice *device;

- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
                  type :(int)type
               logicId :(int)logicId
               unused1 :(int)unused1
               unused2 :(int)unused2
                  mapX :(NSString *)mapX
                  mapY :(NSString *)mapY
         patrolGroupId :(int)patrolGroupId
               CDevice :(CDevice *)device;

- (BOOL)isEqual:(id)object;
- (NSInteger)hash;
@end
