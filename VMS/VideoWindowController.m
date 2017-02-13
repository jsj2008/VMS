//
//  VideoWindowController.m
//  VMS
//
//  Created by mac_dev on 15/8/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoWindowController.h"

@interface VideoWindowController ()
@property (readwrite,assign) int port;
@end

@implementation VideoWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
                      port :(int)port
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.port = port;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
