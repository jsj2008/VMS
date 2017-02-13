//
//  AmbaDetectionAreaEditWindowController.m
//  VMS
//
//  Created by Jeff on 16/4/2.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import "AmbaDetectionAreaEditWindowController.h"

#define STD_OSD_XAXIS_ORIGIN    0.0
#define STD_OSD_YAXIS_ORIGIN    0.0
#define STD_OSD_XAXIS_LENGTH    10000.0
#define STD_OSD_YAXIS_LENGTH    10000.0

@interface AmbaDetectionAreaEditWindowController ()
@property(nonatomic,strong) NSArray *components;
@property(nonatomic,weak) IBOutlet NSView *placeHolder1;
@property(nonatomic,weak) IBOutlet NSView *placeHolder2;
@property(nonatomic,weak) IBOutlet NSView *placeHolder3;
@property(nonatomic,weak) IBOutlet PrivacyCoverEditView *privacyCoverEditView;
@end

@implementation AmbaDetectionAreaEditWindowController

#pragma mark - action
- (IBAction)delete:(id)sender
{
    NSInteger indexOfSelectedArea = self.privacyCoverEditView.indexOfSelectedArea;
    [self.privacyCoverEditView removeAreaAtIndex:indexOfSelectedArea];
}

#pragma mark - public api
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)channelId
                         detectConfig:(FOS_MOTIONDETECTCONFIG1)config
{
    if (self = [super initWithWindowNibName:windowNibName channelId:channelId]) {
        _detectConfig = config;
    }
    
    return self;
}

- (void *)detectConfig
{
    return &_detectConfig;
}

- (void)preDone
{
    //更新motion detect config
    for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
        AmbaDetectComponentViewController *component = [self.components objectAtIndex:i];
        _detectConfig.valid[i] = component.valid;
        _detectConfig.sensitivity[i] = [component sensitivityFromUI];
    }
    
    //areas
    NSArray *textureRects = self.privacyCoverEditView.allAreas;
    assert(textureRects.count <= ANBAMOTIONCOUNT);
    if (textureRects.count > ANBAMOTIONCOUNT) {
        NSLog(@"Warning!!!! Error raised when edit the motion detection areas,count more than limit,exit application");
        exit(0);
    }
    
    int idx = 0;
    for (NSValue *texture in textureRects) {
        NSRect rc = [self rectFromTexture:[texture rectValue] flip:YES];
        _detectConfig.x[idx] = rc.origin.x;
        _detectConfig.y[idx] = rc.origin.y;
        _detectConfig.width[idx] = rc.size.width;
        _detectConfig.height[idx] = rc.size.height;
        ++idx;
    }
    
    for (int i = idx; i < ANBAMOTIONCOUNT; i++) {
        _detectConfig.x[idx] = 0;
        _detectConfig.y[idx] = 0;
        _detectConfig.width[idx] = 0;
        _detectConfig.height[idx] = 0;
    }
}

#pragma mark - texture convert
- (NSRect)rectToTexture :(NSRect)rc flip :(BOOL)flip
{
    CGFloat y = (rc.origin.y  - STD_OSD_YAXIS_ORIGIN) / STD_OSD_YAXIS_LENGTH;
    CGFloat h = (rc.size.height / STD_OSD_YAXIS_LENGTH);
    
    if (flip) {
        y = 1 - y - h;
    }
    
    return NSMakeRect((rc.origin.x - STD_OSD_XAXIS_ORIGIN) / STD_OSD_XAXIS_LENGTH,
                      y,
                      (rc.size.width / STD_OSD_XAXIS_LENGTH),
                      h);
}

- (NSRect)rectFromTexture :(NSRect)rc flip :(BOOL)flip
{
    return NSMakeRect(STD_OSD_XAXIS_ORIGIN + rc.origin.x * STD_OSD_XAXIS_LENGTH,
                      (flip? (STD_OSD_YAXIS_ORIGIN + (1 - rc.origin.y - rc.size.height) * STD_OSD_YAXIS_LENGTH) :
                       (STD_OSD_YAXIS_ORIGIN + rc.origin.y * STD_OSD_YAXIS_LENGTH)),
                      STD_OSD_XAXIS_LENGTH * rc.size.width,
                      STD_OSD_YAXIS_LENGTH * rc.size.height);
}

#pragma mark - setter && getter
- (void)setPlaceHolder:(NSView *)ph atIndex :(NSUInteger)index
{
    NSArray *components = self.components;
    
    if (index < components.count) {
        AmbaDetectComponentViewController *component = components[index];
        
        [ph addSubview:component.view];
        [component.view setFrame:ph.bounds];
    }
}

- (void)setPlaceHolder1:(NSView *)placeHolder1
{
    _placeHolder1 = placeHolder1;
    [self setPlaceHolder:_placeHolder1 atIndex:0];
}

- (void)setPlaceHolder2:(NSView *)placeHolder2
{
    _placeHolder2 = placeHolder2;
    [self setPlaceHolder:_placeHolder2 atIndex:1];
}

- (void)setPlaceHolder3:(NSView *)placeHolder3
{
    _placeHolder3 = placeHolder3;
    [self setPlaceHolder:_placeHolder3 atIndex:2];
}

- (NSArray *)components
{
    if (!_components) {
        NSMutableArray *components = [[NSMutableArray alloc] init];
        for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
            AmbaDetectComponentViewController *component = [[AmbaDetectComponentViewController alloc] initWithNibName:@"AmbaDetectComponentViewController" bundle:[NSBundle mainBundle] index:i];
            component.valid = _detectConfig.valid[i];
            component.sensitivity = _detectConfig.sensitivity[i];
            [components addObject:component];
        }
        
        _components = [NSArray arrayWithArray:components];
    }
    
    return _components;
}

- (void)setPrivacyCoverEditView:(PrivacyCoverEditView *)privacyCoverEditView
{
    _privacyCoverEditView = privacyCoverEditView;
    _privacyCoverEditView.rcCountLimit = 3;
    _privacyCoverEditView.needDisplayIndex = YES;
    
    for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
        NSRect rc = NSMakeRect(_detectConfig.x[i],
                               _detectConfig.y[i],
                               _detectConfig.width[i],
                               _detectConfig.height[i]);
        NSRect tmp = [self rectToTexture:rc flip:YES];
        [_privacyCoverEditView addArea:tmp];
    }
}
@end
