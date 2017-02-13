//
//  Group.h
//  VMS
//
//  Created by mac_dev on 15/7/8.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeNode.h"

@interface Group : TreeNode<NSCopying>

//Group property
@property (assign) int type;
@property (copy) NSString *remark;


- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
                  type :(int)type
                remark :(NSString *)remark;

@end
