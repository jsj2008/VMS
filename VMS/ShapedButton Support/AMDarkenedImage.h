//
//  AMDarkenedImage.h
//  Mandy
//
//  Created by Andreas on Mon Jul 28 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//

//  Tints an image with a given color.
//
//  Unlike other tinting methods this one does not lighten the source image.
//  Instead it adds the tint color to the source (1) which results in a darker look.
//  I found this one better for tinting controls. (Just compositing the tint
//  color with 50% alpha over the source, gives kind of a disabled look since
//  black becomes grey etc.)
//
//  (1) actually it subtracts the difference of the tint color from white;
//      i.e.   result = source - (white - tint)


#import <Cocoa/Cocoa.h>


@interface NSImage (AMDarkenedImage)

- (NSImage *)darkenedImageWithColor:(NSColor *)tint;

@end
