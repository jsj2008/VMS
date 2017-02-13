//
//  Root.h
//  VMS
//
//  Created by Jeff on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeItem.h"

@interface Root : NSObject<TreeItem>
@property (assign) NSInteger uniqueId;
@property (assign) NSInteger type;
@property (copy) NSString *name;
@property (strong,nonatomic,readonly) NSMutableArray *children;

- (id)initWithName :(NSString *)name;
- (void)addChildren:(NSArray *)children;
@end
