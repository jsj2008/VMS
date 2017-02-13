//
//  PrivacyCoverEditWindowController.m
//  
//
//  Created by mac_dev on 16/3/30.
//
//

#import "PrivacyCoverEditWindowController.h"
#define STD_OSD_XAXIS_ORIGIN    0.0
#define STD_OSD_YAXIS_ORIGIN    -40.0
#define STD_OSD_XAXIS_LENGTH    10025.0
#define STD_OSD_YAXIS_LENGTH    10040.0

@interface PrivacyCoverEditWindowController ()

@property(nonatomic,weak) IBOutlet NSView *openglView;
@property(nonatomic,weak) IBOutlet PrivacyCoverEditView *privacyCoverEditView;
@end

@implementation PrivacyCoverEditWindowController

#pragma mark - init
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)chnId
                                areas:(FOS_OSDMASKAREA)areas
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.chnId = chnId;
        self.areas = areas;
        self.port = -1;
    }
    
    return self;
}
#pragma mark - life cycle
- (void)windowDidLoad {
    [super windowDidLoad];
    [self privacyCoverEditView];
    [[NSNotificationCenter defaultCenter] postNotificationName:REGISTERED_RENDER_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self,KEY_RENDER_OBJ,[NSNumber numberWithBool:YES],KEY_REGIST_OR_UNREGIST, nil]];
    //[self printAllAreas];
}

#pragma mark - action
- (IBAction)delete:(id)sender
{
    NSInteger indexOfSelectedArea = self.privacyCoverEditView.indexOfSelectedArea;
    
    if (NSNotFound != indexOfSelectedArea) {
        [self.privacyCoverEditView removeAreaAtIndex:indexOfSelectedArea];
        [self.privacyCoverEditView selectAreaAtIndex:0];
    }
}

- (IBAction)done:(id)sender
{
    NSArray *textureRects = self.privacyCoverEditView.allAreas;
    
    assert(textureRects.count <= FOS_MAX_OSDMASKAREA_COUNT);
    if (textureRects.count > FOS_MAX_OSDMASKAREA_COUNT) {
        NSLog(@"Warning!!!! Error raised when edit the osd areas,count more than limit,exit application");
        exit(0);
    }
    
    int idx = 0;
    FOS_OSDMASKAREA areas = self.areas;
    for (NSValue *texture in textureRects) {
        NSRect rc = [self rectFromTexture:[texture rectValue] flip:YES];
        areas.x1[idx] = rc.origin.x;
        areas.y1[idx] = rc.origin.y;
        areas.x2[idx] = rc.origin.x + rc.size.width;
        areas.y2[idx] = rc.origin.y + rc.size.height;
        ++idx;
    }
    
    for (int i = idx; i < FOS_MAX_OSDMASKAREA_COUNT; i++) {
        areas.x1[i] = 0;
        areas.y1[i] = 0;
        areas.x2[i] = 0;
        areas.y2[i] = 0;
    }
    self.areas = areas;
   //[self printAllAreas];
    [[NSNotificationCenter defaultCenter] postNotificationName:REGISTERED_RENDER_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self,KEY_RENDER_OBJ,[NSNumber numberWithBool:NO],KEY_REGIST_OR_UNREGIST, nil]];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

#pragma mark - video view protocol
- (void)render
{
    [self.openglView.layer setNeedsDisplay];
}

- (void)setPort :(int)port
{
    [(AVPLAYLayer *)self.openglView.layer setPort :port];
}

- (void)clear
{
    OpenGLVidGridLayer *layer = (OpenGLVidGridLayer *)self.openglView.layer;
    [layer clear];
}

- (int)curChannelId
{
    return self.chnId;
}

- (BOOL)isListen
{
    return NO;
}

#pragma mark - private method
//输入参数1:纹理矩形
//输入参数2:输出矩形是否需要翻转
- (NSRect)rectFromTexture :(NSRect)rc flip :(BOOL)flip
{
    return NSMakeRect(STD_OSD_XAXIS_ORIGIN + rc.origin.x * STD_OSD_XAXIS_LENGTH,
                      (flip? (STD_OSD_YAXIS_ORIGIN + (1 - rc.origin.y - rc.size.height) * STD_OSD_YAXIS_LENGTH) :
                      (STD_OSD_YAXIS_ORIGIN + rc.origin.y * STD_OSD_YAXIS_LENGTH)),
                      STD_OSD_XAXIS_LENGTH * rc.size.width,
                      STD_OSD_YAXIS_LENGTH * rc.size.height);
}

//输入参数1:待变换的矩形
//输入参数2:是否翻转
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


- (void)printAllAreas
{
    NSArray *allAreas = [self.privacyCoverEditView allAreas];
    for (int i = 0; i < allAreas.count; i++) {
        NSRect rc = [[allAreas objectAtIndex:i] rectValue];
        NSLog(@"x[%d] = %f,y[%d] = %f,w[%d] = %f,h[%d] = %f",i,rc.origin.x,i,rc.origin.y,i,rc.size.width,i,rc.size.height);
    }
}

#pragma mark - setter && getter
- (void)setOpenglView:(NSView *)openglView
{
    _openglView = openglView;
    _openglView.wantsLayer = YES;
    _openglView.layer = [[AVPLAYLayer alloc] init];
}

- (void)setPrivacyCoverEditView:(PrivacyCoverEditView *)privacyCoverEditView
{
    _privacyCoverEditView = privacyCoverEditView;
    _privacyCoverEditView.rcCountLimit = 4;
    FOS_OSDMASKAREA areas = self.areas;
    for (int i = 0; i < FOS_MAX_OSDMASKAREA_COUNT; i++) {
        NSRect rc = NSMakeRect(MIN(areas.x1[i], areas.x2[i]),
                               MIN(areas.y1[i], areas.y2[i]),
                               abs(areas.x1[i] - areas.x2[i]),
                               abs(areas.y1[i] - areas.y2[i]));
        if (!NSIsEmptyRect(rc)) {
            NSRect tmp = [self rectToTexture:rc flip:YES];
            [_privacyCoverEditView addArea:tmp];
        }
    }
}

@end
