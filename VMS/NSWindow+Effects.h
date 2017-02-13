//
//  NSWindow+Effects.h
//  VMS
//
//  Created by Jeff on 15/10/26.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface NSWindow (Effects)
-(void)shakeWithDuration :(NSTimeInterval)duration
          numberOfShakes :(CGFloat)numberOfShakes
           vigourOfShake :(CGFloat)vigourOfShake
              completion :(void (^)(void))completionBlock;
@end
