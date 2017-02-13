//
//  Root.m
//  VMS
//
//  Created by Jeff on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Root.h"

@interface Root()
@property (readwrite) NSMutableArray *children;
@end

@implementation Root
- (id)initWithName :(NSString *)name
{
    if (self = [super init]) {
        self.uniqueId = -1;
        self.name = name;
        self.type = 100;
    }
    
    return self;
}

- (void)addChildren:(NSArray *)children
{
    [self.children addObjectsFromArray:children];
}
@end
