//
//  PluginFullScreenWindowController.m
//  WebPlugin
//
//  Created by mac_dev on 15/11/11.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "PluginFullScreenWindowController.h"

@implementation PluginFullScreenWindowController


#pragma mark - public api
- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pluginDoubleClickedHandle:)
                                                     name:PLUGIN_DOUBLE_CLICKED_NOTIFICATION
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _shouldEnterFullScreen = NULL;
    _userData = NULL;
}


#pragma mark - public api
- (void)registCallback :(SHOULD_ENTER_FULL_SCREEN)shouldEnterFullScreen
              userData :(void *)userData
{
    _shouldEnterFullScreen = shouldEnterFullScreen;
    _userData = userData;
}


- (void)renderWithData :(const void *)data
              lineSize :(int)lineSize
                videoW :(int)videoW
                videoH :(int)videoH
{
    NSWindow *fullScreenWnd = self.window;
    OpenGLVidGridLayer *fullScreenLayer = (OpenGLVidGridLayer *)[[fullScreenWnd contentView] layer];
   
    dispatch_async(dispatch_get_main_queue(), ^{
        [fullScreenLayer setNeedsDisplay];
    });
}

- (BOOL)isInFullScreenMode
{
    if (self.window)
        return [self.window isFullScreen];

    return NO;
}

- (void)toggleFullScreen
{
    if (!self.window) {
        self.window = [self fullScreenWnd];
        self.window.delegate = self;
    }
    
    [self.window toggleFullScreen:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (theEvent.clickCount == 2) {
        //相应鼠标双击消息，退出全屏模式
        [self toggleFullScreen];
    }
}

//Double Click Notification
- (void)pluginDoubleClickedHandle :(NSNotification *)aNotification
{
    NSDictionary *userInfo = aNotification.userInfo;
    CALayer *mouseDownLayer = [userInfo valueForKey:KEY_PLUGIN_MOUSE_DOWN_LAYER];
    
    if (_shouldEnterFullScreen) {
        bool enterable = _shouldEnterFullScreen(_userData,(__bridge void *)(mouseDownLayer));
        if (enterable) {
            [self toggleFullScreen];
            NSLog(@"Enter Full Screen");
        }
    }
}

#pragma mark - window delegate
- (void)windowDidExitFullScreen:(NSNotification *)notification
{
    [self.window setDelegate:nil];
    [self.window close];
    [self setWindow:nil];
    NSLog(@"Exit Full Screen");
}

#pragma mark - setter && getter
- (NSWindow *)fullScreenWnd
{
    
    unsigned int styleMask = NSResizableWindowMask ;
    NSWindow *fullScreenWnd =
    [[NSWindow alloc] initWithContentRect :NSZeroRect
                                styleMask :styleMask
                                  backing :NSBackingStoreBuffered
                                    defer :NO
                                   screen :nil];
    [fullScreenWnd setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
    [fullScreenWnd.contentView setWantsLayer:YES];
    [fullScreenWnd.contentView setLayer:[[OpenGLVidGridLayer alloc] initWithVId:-1]];
    
    return fullScreenWnd;
}

@end
