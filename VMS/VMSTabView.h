//
//  VMSTabView.h
//  VMS
//
//  Created by mac_dev on 15/11/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol VMSTabViewDelegate <NSObject>

@optional
- (BOOL)shouldRespondHitTestForView :(NSView *)view;

@end

@interface VMSTabView : NSView

@property (nonatomic,assign) IBOutlet id<VMSTabViewDelegate> delegate;

@end
