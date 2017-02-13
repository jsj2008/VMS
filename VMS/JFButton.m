//
//  JFButton.m
//  VMS
//
//  Created by mac_dev on 15/6/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFButton.h"
#import "Image+Clip.h"

@interface JFButton()
{
    NSImage *_images[4]; //four state 0 --- off 1 --- off-pass 2 --- on 3 --- on pass
}

@property (nonatomic,strong)NSTrackingArea *trackingArea;
@end

@implementation JFButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setImageForOnState :(NSImage *)image
{
    NSImageRep* rep = [image bestRepresentationForRect:CGRectZero context:0 hints:0];
    NSSize imgSize = NSMakeSize([rep pixelsWide],[rep pixelsHigh]);
    [image setSize:imgSize];
    
    CGRect image0Rect = CGRectMake(0, 0, imgSize.width/2.0, imgSize.height);
    CGRect image1Rect = CGRectMake(imgSize.width/2.0, 0, imgSize.width/2.0, imgSize.height);
    _images[0] = [image imageClipedWithRect:image0Rect];
    _images[1] = [image imageClipedWithRect:image1Rect];
    
    [self setImage:_images[0]];
}

- (void)setImageForAllState:(NSImage *)image
{
    NSImageRep* rep = [image bestRepresentationForRect:CGRectZero context:0 hints:0];
    NSSize imageSize = NSMakeSize([rep pixelsWide],[rep pixelsHigh]);
    [image setSize:imageSize];
    
    CGRect image0Rect = CGRectMake(0, 0, imageSize.width/4.0, imageSize.height);
    CGRect image1Rect = CGRectMake(imageSize.width/4.0, 0, imageSize.width/4.0, imageSize.height);
    CGRect image2Rect = CGRectMake(imageSize.width * 2/4.0, 0, imageSize.width/4.0, imageSize.height);
    CGRect image3Rect = CGRectMake(imageSize.width * 3/4.0, 0, imageSize.width/4.0, imageSize.height);
    
    _images[0] = [image imageClipedWithRect:image0Rect];
    _images[1] = [image imageClipedWithRect:image1Rect];
    _images[2] = [image imageClipedWithRect:image2Rect];
    _images[3] = [image imageClipedWithRect:image3Rect];
    
    
    [self setImage:_images[0]];
    [self setAlternateImage:_images[2]];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (_images[1]) {
        [self setImage:_images[1]];
    }
    [super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (_images[0]) {
        [self setImage:_images[0]];
    }
    [super mouseExited:theEvent];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    NSTrackingAreaOptions options = NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow;
    
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:options owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}
@end
