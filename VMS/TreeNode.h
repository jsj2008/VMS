//
//  TreeNode.h
//  VMS
//
//  Created by mac_dev on 15/9/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#define TreeNodePasteboardType @"Tree node pasteboard type"

@interface TreeNode : NSObject<NSPasteboardWriting>

@property (assign) int uniqueId;
@property (copy) NSString *name;
@property (copy) NSImage *image;
@property (strong,nonatomic) NSMutableArray *children;

- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name;
- (void)addChildren:(NSArray *)children;
- (void)removeChild :(TreeNode *)child;
@end
