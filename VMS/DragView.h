//
//  DropView.h
//  VMS
//
//  Created by mac_dev on 15/9/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DragView;

@protocol DragViewDelegate <NSObject>
@required
- (NSArray *)dragView :(DragView *)dv draggingItemsAtPoint :(NSPoint)screenPoint;
- (NSDragOperation)dragView :(DragView *)dv validateDrop:(id <NSDraggingInfo>)info;
- (void)dragView :(DragView *)dv draggingSession :(NSDraggingSession *)session
       willBeginAtPoint :(NSPoint)screenPoint;
- (void)dragView :(DragView *)dv draggingSession :(NSDraggingSession *)session
           endedAtPoint :(NSPoint)screenPoint
              operation :(NSDragOperation)operation;
@end



@interface DragView : NSView<NSDraggingDestination,NSDraggingSource>
@property (weak) IBOutlet id<DragViewDelegate> delegate;

@end
