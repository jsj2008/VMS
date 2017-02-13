//
//  PTZButton.h
//  VMS
//
//  Created by mac_dev on 15/10/16.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AMShapedButton.h"

@protocol PTZButtonDelegate <NSObject>

@optional
- (void)ptzButtonDown :(id)sender;
- (void)ptzButtonUp :(id)sender;
@end

@interface PTZButton : AMShapedButton

@property (weak) IBOutlet id<PTZButtonDelegate> delegate;
@end
