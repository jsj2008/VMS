//
//  NSWindow+Effects.m
//  VMS
//
//  Created by Jeff on 15/10/26.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSWindow+Effects.h"

@implementation NSWindow (Effects)


-(void)shakeWithDuration :(NSTimeInterval)duration
          numberOfShakes :(CGFloat)numberOfShakes
           vigourOfShake :(CGFloat)vigourOfShake
              completion :(void (^)(void))completionBlock{
    [CATransaction begin];
    [CATransaction setCompletionBlock:completionBlock];
    NSRect frame = [self frame];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"frame"];
    
    NSRect rect1 = NSMakeRect(NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
    NSRect rect2 = NSMakeRect(NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
    NSArray *arr = [NSArray arrayWithObjects:[NSValue valueWithRect:rect1], [NSValue valueWithRect:rect2], nil];
    [animation setValues:arr];
    [animation setDuration:duration];
    [animation setRepeatCount:numberOfShakes];
    
    [self setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"frame"]];
    [[self animator] setFrame:frame display:NO];
    [CATransaction commit];
}
@end
