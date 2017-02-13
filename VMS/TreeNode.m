//
//  TreeNode.m
//  VMS
//
//  Created by mac_dev on 15/9/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "TreeNode.h"

@implementation TreeNode

#pragma mark - init
- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.name = name;
    }
    
    return self;
}

#pragma mark - public api
- (void)addChildren:(NSArray *)children
{
    [self.children addObjectsFromArray:children];
}


- (void)removeChild :(TreeNode *)child
{
    [self.children removeObject:child];
}


#pragma mark - pasteboard writting protocol
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSArray *ourTypes = @[NSPasteboardTypeString];
    NSArray *imageTypes = [self.image writableTypesForPasteboard:pasteboard];
    if (imageTypes) {
        ourTypes = [ourTypes arrayByAddingObjectsFromArray:imageTypes];
    }
    return ourTypes;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    return self.name;
}


#pragma mark - setter && getter
- (NSMutableArray *)children
{
    if (!_children) {
        _children = [[NSMutableArray alloc] init];
    }
    
    return _children;
}
@end
