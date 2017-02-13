//
//  NSImage+SaveAsJpegWithName.h
//  VMS
//
//  Created by mac_dev on 15/11/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (SaveAsJpegWithName)
- (void) saveAsJpegWithName:(NSString*) fileName;
- (BOOL)saveAsBmpWithName :(NSString *)fileName;
@end
