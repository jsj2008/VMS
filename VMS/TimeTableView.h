//
//  TimeTableView.h
//  VMS
//
//  Created by mac_dev on 15/6/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFBackground.h"


#define POSITION_DID_CHANGE_NOTIFICATION    @"position did change notification"
#define SELECTION_DID_CHANGE_NOTIFICATION   @"selection did change notification"
#define KEY_GROUP                           @"group"
#define KEY_ROW                             @"row"
#define KEY_TYPE                            @"type"
#define KEY_POINTS                          @"points"


typedef struct _TTV_NODE
{
    CGFloat x;
    CGFloat y;
    int type;
}TTV_NODE;


@class TimeTableView;
@protocol TimeTableViewDelegate<NSObject>
@required
- (NSUInteger)numberOfGroupInTimeTable :(NSView *)view;
- (NSUInteger)numberOfRowAtGroupIdx :(NSUInteger)idx inTimeTableView :(NSView *)view;
- (BOOL)timeTableView :(NSView *)view shouldCheckGroup :(NSUInteger)g row :(NSUInteger)r;
- (NSString *)timeTableView :(NSView *)view titleForGroup :(NSUInteger)g row :(NSUInteger)r;
- (NSArray *)timeTableView :(NSView *)view dateRangesForGroup :(NSUInteger)g row :(NSUInteger)r;

@optional
- (BOOL)shouldHittedTimeTableView :(NSView *)view;
- (void)selectionDidChangeNotification :(NSNotification *)aNotific;
- (void)positionDidChangeNotification :(NSNotification *)aNotific;
@end


@interface TimeTableView : JFBackground

@property (nonatomic,assign) IBOutlet id<TimeTableViewDelegate> delegate;
@property (nonatomic,assign,getter=isSelectable) BOOL selectable;

@property (nonatomic,weak) IBOutlet NSLayoutConstraint *topConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *widthConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *heightConstraint;

+ (NSColor *)colorForType :(int)type;
- (void)modifyFrameRect;
- (CGFloat)positionOfGroup :(NSUInteger)g;
- (void)setPosition :(CGFloat)p ForGroup :(NSUInteger)g;
- (void)reloadData;

@end



