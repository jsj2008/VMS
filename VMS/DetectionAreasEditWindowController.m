//
//  DetectionAreasEditWindowController.m
//  VMS
//
//  Created by mac_dev on 15/9/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DetectionAreasEditWindowController.h"

@interface DetectionAreasEditWindowController ()<NSWindowDelegate>
@property (nonatomic,readwrite,assign) NSInteger channelId;
@end

@implementation DetectionAreasEditWindowController

#pragma mark - public(overwriter these methods)
- (void *)detectConfig
{
    return nil;
}

- (void)preDone
{}

#pragma mark - init
- (instancetype)initWithWindowNibName:(NSString *)windowNibName channelId :(int)channelId
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.channelId = channelId;
        self.port = -1;
    }
    
    return self;
}

#pragma mark - life circle
- (void)windowDidLoad {
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] postNotificationName:REGISTERED_RENDER_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self,KEY_RENDER_OBJ,[NSNumber numberWithBool:YES],KEY_REGIST_OR_UNREGIST, nil]];
}

#pragma mark - action
- (IBAction)done :(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REGISTERED_RENDER_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self,KEY_RENDER_OBJ,[NSNumber numberWithBool:NO],KEY_REGIST_OR_UNREGIST, nil]];
    [self preDone];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REGISTERED_RENDER_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self,KEY_RENDER_OBJ,[NSNumber numberWithBool:NO],KEY_REGIST_OR_UNREGIST, nil]];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}


#pragma mark - video view protocol
- (void)setPort:(int)port
{
    _port = port;
    [(AVPLAYLayer *)self.renderView.layer setPort:port];
}

- (void)render
{
    [self.renderView.layer setNeedsDisplay];
}

- (void)clear
{
    OpenGLVidGridLayer *layer = (OpenGLVidGridLayer *)self.renderView.layer;
    [layer clear];
}

- (int)curChannelId
{
    return self.channelId;
}


- (BOOL)isListen
{
    return NO;
}


#pragma mark - setter && getter

- (void)setRenderView:(NSView *)renderView
{
    _renderView = renderView;
    _renderView.wantsLayer = YES;
    _renderView.layer = [[AVPLAYLayer alloc] init];
}


@end
