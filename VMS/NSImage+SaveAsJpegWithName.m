//
//  NSImage+SaveAsJpegWithName.m
//  VMS
//
//  Created by mac_dev on 15/11/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSImage+SaveAsJpegWithName.h"

@implementation NSImage (SaveAsJpegWithName)
- (void)saveAsJpegWithName:(NSString*) fileName
{
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:fileName atomically:NO];
}

- (BOOL)saveAsBmpWithName :(NSString *)fileName
{
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSBMPFileType properties:imageProps];
    return [imageData writeToFile:fileName atomically:NO];
}
@end
