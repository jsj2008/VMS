//
//  AMShapedButton.m
//  Mandy
//
//  Created by Andreas on Mon Jul 28 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//
//  2003-08-06 AM	updated to allow On/Off type buttons
//  2004-06-14 AM	fixed controlTintChanged: to not overwrite the alternate
//					image if there are no separate aqua/graphite versions


#import "AMShapedButton.h"
#import "AMDarkenedImage.h"


@implementation JFButtonCell

- (void)drawImage:(NSImage *)image
        withFrame:(NSRect)frame
           inView:(NSView *)controlView
{
    BOOL isHover = self.isHover;
    BOOL isEnable = self.isEnabled;
    BOOL isHighLighted = self.isHighlighted;
    if (isHover && !isHighLighted) {
        NSImage *hoverImage = self.hoverImage;
        
        if (hoverImage) {
            image = hoverImage;
        }
    } else if (isHover && isHighLighted) {
        NSImage *alternateHoverImage = self.alternateHoverImage;
        
        if (alternateHoverImage) {
            image = alternateHoverImage;
        }
    } else if (!isEnable) {
        NSImage *disableImage = self.disableImage;
        
        if (!disableImage) {
            disableImage = [image darkenedImageWithColor:[[NSColor controlHighlightColor] colorWithAlphaComponent:0.5]];
        }
        image = disableImage;
    }
    
    [super drawImage:image withFrame:frame inView:controlView];
}

- (NSImage *)hoverImage
{
    if (!_hoverImage) {
        NSString *imageBaseName = [self.image name];
        NSString *hoverImageName = [NSString stringWithFormat:@"%@ Hover",imageBaseName];
        _hoverImage = [NSImage imageNamed:hoverImageName];
    }
    return _hoverImage;
}

- (NSImage *)alternateHoverImage
{
    if (!_alternateHoverImage) {
        NSString *imageBaseName = [self.alternateImage name];
        NSString *hoverImageName = [NSString stringWithFormat:@"%@ Hover",imageBaseName];
        _alternateHoverImage = [NSImage imageNamed:hoverImageName];
    }
    return _alternateHoverImage;
}

- (NSImage *)disableImage
{
    if (!_disableImage) {
        NSString *imageBaseName = [self.image name];
        NSString *disableImageName = [NSString stringWithFormat:@"%@ Disable",imageBaseName];
        _disableImage = [NSImage imageNamed:disableImageName];
    }
    return _disableImage;
}

- (NSImage *)alternateDisableImage
{
    if (!_alternateDisableImage) {
        NSString *imageBaseName = [self.alternateImage name];
        NSString *disableImageName = [NSString stringWithFormat:@"%@ Disable",imageBaseName];
        _alternateDisableImage = [NSImage imageNamed:disableImageName];
    }
    return _alternateDisableImage;
}

@end


@interface AMShapedButton ()

@end

@implementation AMShapedButton


- (void)updateTrackingAreas
{
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    [super updateTrackingAreas];
}



- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    id cell = self.cell;
    if ([cell isKindOfClass:[JFButtonCell class]]) {
        JFButtonCell *hoverCell = cell;
        [hoverCell setHover:YES];
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    id cell = self.cell;
    if ([cell isKindOfClass:[JFButtonCell class]]) {
        JFButtonCell *hoverCell = cell;
        [hoverCell setHover:NO];
    }
    [self setNeedsDisplay:YES];
}


- (NSView *)hitTest:(NSPoint)aPoint
{
	// NSView instance method
	// Returns the farthest descendant of the receiver in the view hierarchy
	// (including itself) that contains aPoint, or nil if aPoint lies completely
	// outside the receiver. aPoint is in the coordinate system of the receiver's
	// superview, not of the receiver itself.

	NSView *result = self;
	NSPoint thePoint = [[self superview] convertPoint:aPoint toView:self];
	if (!NSPointInRect(thePoint, [self bounds])) {
		result = nil;
	} else {
		// get alpha mask of button image
		NSImageRep *imageRep = (NSImageRep *)[[[self image] representations] objectAtIndex:0];
		if (imageRep) {
			if ([imageRep hasAlpha]) {
				if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
					if ([(NSBitmapImageRep *)imageRep isPlanar]) {
						NSLog(@"planar bitmap formats not supported");
					} else {
						if (([(NSBitmapImageRep *)imageRep bitsPerPixel]/[(NSBitmapImageRep *)imageRep samplesPerPixel]) != 8) {
							NSLog(@"Bits per Pixel/Samples per Pixel != 8: %ld/%ld", (long)[(NSBitmapImageRep *)imageRep bitsPerPixel], (long)[(NSBitmapImageRep *)imageRep samplesPerPixel]);
						} else {
							unsigned char *bitmapData = [(NSBitmapImageRep *)imageRep bitmapData];
							// calculate byte position
							// 1. skip rows
							int bytePos = trunc(thePoint.y) * [(NSBitmapImageRep *)imageRep bytesPerRow];
							// 2. add column
							bytePos += trunc(thePoint.x) * [(NSBitmapImageRep *)imageRep bitsPerPixel]/8;
							// 3. skip RGB values
							bytePos += 3;
							int alphaValue = bitmapData[bytePos];
							if (alphaValue < 128) {
								result = nil;
							}
						}
					}
				}
			}
		}
	}
	return result;
}

@end
