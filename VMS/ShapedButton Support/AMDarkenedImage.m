//
//  AMDarkenedImage.m
//  Mandy
//
//  Created by Andreas on Mon Jul 28 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//
//	2005-05-05	Andreas Mayer
//	- 10.4 supports various bitmap formats (and default is premultiplied alpha),
//		so we have to make sure to use the same format as the source bitmap.
//		(Our coloring algorithm won't work right if alpha is premultiplied, but fortunately that
//		does not seem to be the case for images loaded from disk.)


#import "AMDarkenedImage.h"


@implementation NSImage (AMDarkenedImage)

- (NSImage *)darkenedImageWithColor:(NSColor *)tint
{
	NSImage *result = nil;
	NSSize size = [self size];
	
	NSImageRep *imageRep = [[self representations] objectAtIndex:0];
	if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
		NSBitmapImageRep *bitmapImageRep = nil;
		
		if ([imageRep respondsToSelector:@selector(bitmapFormat)]) {
			bitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:[(NSBitmapImageRep *)imageRep bitmapFormat] bytesPerRow:0 bitsPerPixel:0];
		} else {
			bitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
		}
		result = [[NSImage alloc] initWithSize:size] ;

		// get RGB components from tint color
		NSColor *rgbTint = [tint colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		// get bitmap data
		unsigned char *sourceData = [(NSBitmapImageRep *)imageRep bitmapData];
		unsigned char *destData = [bitmapImageRep bitmapData];
		NSInteger x, y, sourcePos, destPos;
		NSInteger sourceBytesPerRow = [(NSBitmapImageRep *)imageRep bytesPerRow];
		NSInteger sourceBytesPerPixel = [(NSBitmapImageRep *)imageRep bitsPerPixel]/8;
		NSInteger destBytesPerRow = [bitmapImageRep bytesPerRow];
		NSInteger destBytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
		int value;
		int redTint = (256 - [rgbTint redComponent]*255);
		int greenTint = (256 - [rgbTint greenComponent]*255);
		int blueTint = (256 - [rgbTint blueComponent]*255);
		// process pixels
		for (x = 0; x < size.width; x++) {
			for (y = 0; y < size.height; y++) {
				sourcePos = (y * sourceBytesPerRow) + (x * sourceBytesPerPixel);
				destPos = (y * destBytesPerRow) + (x * destBytesPerPixel);
				value = sourceData[sourcePos] - redTint;
				destData[destPos] = ((value > 0) ? value : 0);
				value = sourceData[++sourcePos] - greenTint;
				destData[++destPos] = ((value > 0) ? value : 0);
				value = sourceData[++sourcePos] - blueTint;
				destData[++destPos] = ((value > 0) ? value : 0);
				// copy alpha from source
				destData[++destPos] = sourceData[++sourcePos];
			}
		}
		[result addRepresentation:bitmapImageRep];
	} else {
		NSLog(@"not a bitmap image rep");
	}
	return result;
}

@end
