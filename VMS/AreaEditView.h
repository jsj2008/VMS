//
//  AreaEditView.h
//  VMS
//
//  Created by mac_dev on 15/10/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ROWS    10
#define COLS    10

@protocol AreaEditViewDelegate <NSObject>

@required
- (BOOL)editView :(NSView *)view
shouldCoverAtRow :(int)row
          column :(int)col;

@optional
- (void)alterCoverFromRowStart :(int)rStart
                      colStart :(int)cStart
                      toRowEnd :(int)rEnd
                        colEnd :(int)cEnd
                      editView :(NSView *)view;

@end

@interface AreaEditView : NSView

@property (nonatomic,assign) IBOutlet id<AreaEditViewDelegate> delegate;

@end
