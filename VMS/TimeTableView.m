//
//  TimeTableView.m
//  VMS
//
//  Created by mac_dev on 15/6/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "TimeTableView.h"
#import "VerticallyCenteredTFCell.h"

#define DEFAULT_ROWS                            4
#define COL_WIDTH_MIN                           32.0//最小的列宽
#define ROW_HEIGHT                              32.0
#define DEVICE_COLUMN_WIDTH                     128.0
#define TIME_COLUMN_WIDTH                       72.0
#define TOP_BLANK_SPACE_HEIGHT                  30.0
#define BOTTOM_BLANK_SPACE_HEIGHT               5.0
#define LEFT_BLANK_SPACE_WIDTH                  5.0
#define RIGHT_BLANK_SPACE_WIDTH                 32.0
#define HOURS                                   24.0
#define MOMENT_DISPLAY_OFFSET                   0
#define CHECK_BOX_OFFSET                        -8
#define LONG_SCALE_LENGTH                       8
#define SHORT_SCALE_LENGTH                      6
#define GROUP_COLOR_CNT                         3

@interface TimeTableView()

@property (strong) NSTrackingArea *trackingArea;
@property (assign) NSPoint location;
@property (strong,nonatomic) VerticallyCenteredTFCell *cellTextfield;//used to draw unselectable column header
@property (strong,nonatomic) NSButtonCell *cellCheckBox;//used to draw selectable column header
@property (strong,nonatomic) NSMutableDictionary *positions;
@property (strong,nonatomic) NSArray *groupColors;

@end

@implementation TimeTableView

#pragma mark - init
- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    //[self.superview removeObserver:self forKeyPath:@"frame"];
}

#pragma mark - public api
+ (NSColor *)colorForType :(int)type
{
    NSArray *colors = @[[NSColor blueColor],
                        [NSColor greenColor],
                        [NSColor redColor]];
    
    if (type < colors.count)
        return colors[type];
    
    return [NSColor blueColor];
}


- (CGFloat)positionOfGroup :(NSUInteger)g
{
    NSString *key = [NSString stringWithFormat:@"%ld",g];
    return [(NSNumber *)[self.positions valueForKey:key] doubleValue];
}

- (void)setPosition :(CGFloat)p ForGroup :(NSUInteger)g
{
    NSString *key = [NSString stringWithFormat:@"%ld",g];
    [self.positions setValue:[NSNumber numberWithDouble:p] forKey:key];
    [self setNeedsDisplay:YES];
}

- (void)reloadData
{
    [self modifyFrameRect];
    [self setNeedsDisplay:YES];
}
#pragma mark - flip
- (BOOL)isFlipped{
    return YES;
}

#pragma mark - draw
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawContents];
    [self drawGridLines];
    [self drawScaleLine];
    [self drawMomentLine];
}


//画刻度线
- (void)drawScaleLine
{
    int cnt = 120;
    CGFloat det = (self.bounds.size.width - LEFT_BLANK_SPACE_WIDTH - DEVICE_COLUMN_WIDTH - RIGHT_BLANK_SPACE_WIDTH) / cnt;
    CGFloat x,y;
    for (int i = 0; i <= cnt; i++) {
        //0代表长刻度
        x = LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + i*det;
        
        if (i % 10 == 0) {
            y = TOP_BLANK_SPACE_HEIGHT - LONG_SCALE_LENGTH;
            //画时刻点
            
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            style.alignment = NSCenterTextAlignment;
            NSDictionary *attr = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
            [[NSString stringWithFormat:@"%02d:00",(i / 10) * 2] drawInRect:NSMakeRect(x - 24, 4, 48, 18)
                                                             withAttributes:attr];
        } else {
            y = TOP_BLANK_SPACE_HEIGHT - SHORT_SCALE_LENGTH;
        }

        [NSBezierPath strokeLineFromPoint:CGPointMake(x, y)
                                  toPoint:CGPointMake(x, TOP_BLANK_SPACE_HEIGHT)];
    }
}

//画网格线
- (void)drawGridLines
{
    id<TimeTableViewDelegate> datasource = self.delegate;
    NSInteger rows = 0;
    
    if ([datasource respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [datasource respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
       
        NSUInteger groups = [datasource numberOfGroupInTimeTable:self];
        
        for (NSUInteger g = 0; g < groups; g++) {
            rows += [datasource numberOfRowAtGroupIdx:g inTimeTableView:self];
        }
    }
    
    if (rows < DEFAULT_ROWS) {
        rows = DEFAULT_ROWS;
    }
    
    CGRect  bounds  = self.bounds;
    CGFloat BW      = bounds.size.width;
    ///draw row
    [[NSColor blackColor] set];
    for (NSInteger row = 0; row <= rows; row++) {
        NSPoint left = CGPointMake(LEFT_BLANK_SPACE_WIDTH, TOP_BLANK_SPACE_HEIGHT + row * ROW_HEIGHT);
        NSPoint right   = CGPointMake(BW - RIGHT_BLANK_SPACE_WIDTH, TOP_BLANK_SPACE_HEIGHT + row * ROW_HEIGHT);
        [NSBezierPath strokeLineFromPoint:left toPoint:right];
    }

    ///draw column
    CGFloat topY = TOP_BLANK_SPACE_HEIGHT;
    CGFloat bottomY = topY + ROW_HEIGHT * rows;
    CGFloat flowColumnWidth = [self flowColumnWidth];
    if (flowColumnWidth < COL_WIDTH_MIN) {
        flowColumnWidth = COL_WIDTH_MIN;
    }
    
    [NSBezierPath strokeLineFromPoint:CGPointMake(LEFT_BLANK_SPACE_WIDTH, topY)
                              toPoint:CGPointMake(LEFT_BLANK_SPACE_WIDTH, bottomY)];
    NSInteger cols[2] = {0,HOURS};
    for (int i = 0; i < 2; i++) {
        NSPoint     top     = CGPointMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + cols[i] * flowColumnWidth,topY);
        NSPoint     bottom  = CGPointMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + cols[i] * flowColumnWidth,bottomY);
        
        [NSBezierPath strokeLineFromPoint:bottom toPoint:top];
    }
}

- (void)drawContents
{
    id<TimeTableViewDelegate> datasource = self.delegate;
    if ([datasource respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [datasource respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
        
        NSUInteger rowTotal = 0;
        NSUInteger groups = [datasource numberOfGroupInTimeTable:self];
        
        for (NSUInteger g = 0; g < groups; g++) {
            NSUInteger rows = [datasource numberOfRowAtGroupIdx:g inTimeTableView:self];
            for (NSInteger r = 0; r < rows; r++) {
                BOOL checked = NO;
                if ([datasource respondsToSelector:@selector(timeTableView:shouldCheckGroup:row:)]) {
                    checked = [datasource timeTableView:self shouldCheckGroup:g row:r];
                }
                
                NSString    *title = @"";
                CGRect      titleRect = CGRectMake(LEFT_BLANK_SPACE_WIDTH,
                                                   TOP_BLANK_SPACE_HEIGHT + rowTotal * ROW_HEIGHT,
                                                   DEVICE_COLUMN_WIDTH,
                                                   ROW_HEIGHT);
                if ([datasource respondsToSelector:@selector(timeTableView:titleForGroup:row:)]) {
                    title = [datasource timeTableView:self titleForGroup:g row:r];
                }
                
                [self drawTitle :title withChecked:checked inRect :titleRect];
                
                
                NSArray *dateRanges = nil;
                NSRect  rangesRect = CGRectMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH,
                                                TOP_BLANK_SPACE_HEIGHT + rowTotal * ROW_HEIGHT,
                                                self.bounds.size.width - LEFT_BLANK_SPACE_WIDTH - DEVICE_COLUMN_WIDTH - RIGHT_BLANK_SPACE_WIDTH,
                                                ROW_HEIGHT);
                
                if ([datasource respondsToSelector:@selector(timeTableView:dateRangesForGroup:row:)]) {
                    dateRanges = [datasource timeTableView:self dateRangesForGroup:g row:r];
                }
                
                [self drawDateRanges:dateRanges inRect:rangesRect];
                
                rowTotal++;
            }
        }
    }
}


- (void)drawMomentLine
{
    id<TimeTableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
        
        NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
        NSUInteger rows = 0;
        CGFloat position;
        
        for (NSUInteger g = 0; g < groups; g++) {
            NSUInteger tmp = rows;
            rows += [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
            position = [self positionOfGroup:g] * [self flowColumnWidth] * 24.0;
            CGPoint bottom = CGPointMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + position, TOP_BLANK_SPACE_HEIGHT + rows* ROW_HEIGHT);
            CGPoint top = CGPointMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + position, TOP_BLANK_SPACE_HEIGHT + tmp * ROW_HEIGHT);
            [(NSColor *)[self.groupColors objectAtIndex:(g % GROUP_COLOR_CNT)] set];
            [NSBezierPath strokeLineFromPoint:bottom toPoint:top];
        }
    }
}


- (void)drawTitle :(NSString *)title withChecked :(BOOL)checked inRect :(NSRect)rect
{
    if (title) {
        NSRect cellRect = NSMakeRect(rect.origin.x + 8, rect.origin.y, rect.size.width - 8, rect.size.height);
        if (self.isSelectable) {
            [self.cellCheckBox setTitle:title];
            [self.cellCheckBox setObjectValue:[NSNumber numberWithBool:checked]];
            [self.cellCheckBox drawWithFrame:cellRect inView:self];
        }
        else {
            [self.cellTextfield setTitle:title];
            [self.cellTextfield drawWithFrame:cellRect inView:self];
        }
    }
}

//- (void)drawTitle :(NSString *)title
//      withChecked :(BOOL)checked
//           inRect :(NSRect)rect
//{
//    if (title) {
//        ///draw the title
//        ///prepare to draw the text
//        NSMutableParagraphStyle *phStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//        [phStyle setAlignment:NSCenterTextAlignment];
//        
//        NSFont *font = [NSFont fontWithName:@"Times" size:13];
//        NSDictionary *textAttributes = @{NSFontAttributeName : font,
//                                         NSForegroundColorAttributeName : [NSColor  blackColor],
//                                         NSParagraphStyleAttributeName : phStyle};
//        NSSize titleSize = [title sizeWithAttributes:textAttributes];
//        NSRect titleRect = CGRectMake(rect.origin.x - (self.isSelectable? CHECK_BOX_OFFSET : 0) + 16,
//                                      rect.origin.y + (rect.size.height - titleSize.height) / 2,
//                                      titleSize.width,
//                                      titleSize.height);
//        [title drawInRect:titleRect withAttributes:textAttributes];
//        
//        if (self.isSelectable) {
//            //[self.cellCheckBox setTitle:title];
//            [self.cellCheckBox setObjectValue:[NSNumber numberWithBool:checked]];
//            [self.cellCheckBox drawWithFrame:NSMakeRect(rect.origin.x - CHECK_BOX_OFFSET,
//                                                        rect.origin.y,
//                                                        32,
//                                                        32) inView:self];
//        }
//    }
//}

- (void)drawDateRanges :(NSArray *)dateRanges inRect :(NSRect)rect
{
    for (NSValue *val in dateRanges) {
        TTV_NODE node;
        [val getValue:&node];
        
        [[TimeTableView colorForType:node.type] set];
    
        if (node.x < 0 || node.x >1 || node.y < 0 || node.y >1 || node.x > node.y) {
            continue;
        }
        
        [[NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x + node.x * rect.size.width,
                                                     rect.origin.y,
                                                     (node.y - node.x) *rect.size.width,
                                                     rect.size.height)] fill];
    }
}


- (CGFloat)precision
{
    return [self flowColumnWidth] / 3600;
}

- (CGFloat)flowColumnWidth
{
    CGFloat BW = self.bounds.size.width;
    CGFloat flowColumnWidth = (BW - (LEFT_BLANK_SPACE_WIDTH + RIGHT_BLANK_SPACE_WIDTH) - DEVICE_COLUMN_WIDTH) / HOURS;
    
    if (flowColumnWidth < 0) {
        flowColumnWidth = 0;
    }
    
    return flowColumnWidth;
}

#pragma mark - mouse event
- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    NSTrackingAreaOptions options = NSTrackingMouseMoved|NSTrackingActiveInKeyWindow;
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                     options:options
                                                       owner:self
                                                    userInfo:nil];
    
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [super mouseMoved:theEvent];
    self.location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    NSUInteger rows = 0;
    id<TimeTableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)]) {
        NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
        if ([delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
            for (NSUInteger g = 0; g < groups; g++) {
                rows += [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
            }
        }
    }
    
    if (rows < DEFAULT_ROWS) {
        rows = DEFAULT_ROWS;
    }
    
    NSRect rc = NSMakeRect(LEFT_BLANK_SPACE_WIDTH,
                           TOP_BLANK_SPACE_HEIGHT,
                           self.bounds.size.width - LEFT_BLANK_SPACE_WIDTH - RIGHT_BLANK_SPACE_WIDTH,
                           rows * ROW_HEIGHT);
    [self removeAllToolTips];
    [self addToolTipRect:rc owner:self userData:NULL];
    [self setNeedsDisplay:YES];
}


- (NSView *)hitTest:(NSPoint)aPoint
{
    BOOL hittable = YES;
    if ([self.delegate respondsToSelector:@selector(shouldHittedTimeTableView:)])
        hittable = [self.delegate shouldHittedTimeTableView:self];
    
    return hittable? [super hitTest:aPoint] : nil;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    id<TimeTableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
        
        NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
        NSUInteger rows = 0;
        CGPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        for (NSUInteger g = 0; g < groups; g++) {
            NSUInteger tmp = [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
            NSRect rc = NSMakeRect(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH,
                                   TOP_BLANK_SPACE_HEIGHT + rows * ROW_HEIGHT,
                                   self.bounds.size.width - LEFT_BLANK_SPACE_WIDTH - DEVICE_COLUMN_WIDTH - RIGHT_BLANK_SPACE_WIDTH,
                                   tmp * ROW_HEIGHT);
            rows += tmp;
            if (NSPointInRect(pt, rc)) {
                CGFloat distFromZero = pt.x - (LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH);
                CGFloat position = distFromZero / ([self flowColumnWidth] * HOURS);
                
                if ([self positionOfGroup:g] != position) {
                    [self setPosition:position ForGroup:g];
                    
                    if ([delegate respondsToSelector:@selector(positionDidChangeNotification:)]) {
                        [delegate positionDidChangeNotification:[NSNotification notificationWithName:POSITION_DID_CHANGE_NOTIFICATION
                                                                                              object:self
                                                                                            userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:g] forKey:KEY_GROUP]]];
                    }
                    
                    [self setNeedsDisplay:YES];
                    break;
                }
            }
        }
    }
    
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (self.selectable) {
        id<TimeTableViewDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
            [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
            
            NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
            CGPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            NSUInteger rows = 0;
            
            for (NSUInteger g = 0; g < groups; g++) {
                NSUInteger tmp = [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
                NSRect rc = NSMakeRect(LEFT_BLANK_SPACE_WIDTH,
                                       TOP_BLANK_SPACE_HEIGHT + rows * ROW_HEIGHT,
                                       DEVICE_COLUMN_WIDTH,
                                       tmp * ROW_HEIGHT);
                if (NSPointInRect(pt, rc)) {
                    NSPoint location = [self pointToLocation:pt];
                    NSUInteger row = location.y;
                    if ([self.delegate respondsToSelector:@selector(selectionDidChangeNotification:)]) {
                        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                        [userInfo setValue:[NSNumber numberWithUnsignedInteger:g] forKey:KEY_GROUP];
                        [userInfo setValue:[NSNumber numberWithUnsignedInteger:row - rows] forKey:KEY_ROW];
                        [self.delegate selectionDidChangeNotification:[NSNotification notificationWithName:SELECTION_DID_CHANGE_NOTIFICATION
                                                                                                    object:self
                                                                                                  userInfo:userInfo]];
                    }
                }
                rows += tmp;
            }
        }
    }

    [super mouseUp:theEvent];
}


#pragma mark - private method
- (void)getHour :(int *)hour minute:(int *)min second:(int *)sec fromPosition :(CGFloat)position
{
    int secsPerHour = 60 * 60;
    int secsPerMin = 60;
    int total = 24 * secsPerHour * position;
    
    *hour = total / secsPerHour;
    *min = (total - (*hour) * secsPerHour) / secsPerMin;
    *sec = total - (*hour) *secsPerHour - (*min)*secsPerMin;
}

- (void)modifyFrameRect
{
    NSUInteger rows = 0;
    id<TimeTableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
        
        NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
        for (NSUInteger g = 0; g < groups; g++) {
            rows += [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
        }
    }
    
    if (rows < DEFAULT_ROWS) {
        rows = DEFAULT_ROWS;
    }
    

    CGFloat BW =  self.superview.bounds.size.width;
    CGFloat BH = self.superview.bounds.size.height;
    CGFloat BWMin = LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH + HOURS * COL_WIDTH_MIN + RIGHT_BLANK_SPACE_WIDTH;
    CGFloat BHMin = TOP_BLANK_SPACE_HEIGHT + rows * ROW_HEIGHT + BOTTOM_BLANK_SPACE_HEIGHT;
    
    
    self.widthConstraint.constant = (BW < BWMin)? BWMin : BW;
    self.heightConstraint.constant = (BH < BHMin)? BHMin : BH;
}

#pragma mark - tool tip
- (NSString *)titleOfRow :(int)row
{
    id<TimeTableViewDelegate> delegate = self.delegate;
    NSString *title = nil;
    
    if (row >= 0) {
        if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
            [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
            
            NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
            
            int cnt = 0;
            for (NSUInteger g = 0; g < groups; g++) {
                NSUInteger rows = [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
                
                int r = -1;
                for (int i = 0; i < rows; i++) {
                    if (++cnt == row + 1) {
                        r = i;
                        break;
                    }
                }
                
                if ((r >= 0) && [delegate respondsToSelector:@selector(timeTableView:titleForGroup:row:)]) {
                    title = [delegate timeTableView:self titleForGroup:g row:r];
                    break;
                }
            }
        }
    }
    
    return title;
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data
{
    int h,m,s;
    
    NSUInteger rows = 0;
    id<TimeTableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(numberOfGroupInTimeTable:)] &&
        [delegate respondsToSelector:@selector(numberOfRowAtGroupIdx:inTimeTableView:)]) {
        
        NSUInteger groups = [delegate numberOfGroupInTimeTable:self];
        for (NSUInteger g = 0; g < groups; g++) {
            rows += [delegate numberOfRowAtGroupIdx:g inTimeTableView:self];
        }
    }
    
    if (rows < DEFAULT_ROWS) {
        rows = DEFAULT_ROWS;
    }
    
    CGFloat BW              = self.bounds.size.width;
    CGFloat position        = 0;
    CGFloat width           = BW - LEFT_BLANK_SPACE_WIDTH - DEVICE_COLUMN_WIDTH - RIGHT_BLANK_SPACE_WIDTH;
    CGRect  dateRangesRect  = CGRectMake(LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH,
                                         TOP_BLANK_SPACE_HEIGHT,
                                         BW - (LEFT_BLANK_SPACE_WIDTH + RIGHT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH),
                                         rows * ROW_HEIGHT);
    CGRect titleRect        = CGRectMake(LEFT_BLANK_SPACE_WIDTH, TOP_BLANK_SPACE_HEIGHT, DEVICE_COLUMN_WIDTH, rows * ROW_HEIGHT);
    if (CGRectContainsPoint(dateRangesRect, self.location)) {
        position = (self.location.x - (LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH))/width;
        
        [self getHour:&h minute:&m second:&s fromPosition:position];
        
        return [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
    }
    else if (CGRectContainsPoint(titleRect, self.location)) {
        //根据y坐标，获取具体的行
        int row = (self.location.y - TOP_BLANK_SPACE_HEIGHT) / ROW_HEIGHT;
        
        return [self titleOfRow:row];
    }
    /*else if (self.location.x < (LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH)) {
        position = 0.0;
        //显示完整title
    } else if (self.location.x > (BW - RIGHT_BLANK_SPACE_WIDTH)) {
        return nil;
    }*/

    return nil;
}

- (NSPoint)pointToLocation :(NSPoint)point
{
    
    return NSMakePoint((point.x - (LEFT_BLANK_SPACE_WIDTH + DEVICE_COLUMN_WIDTH))/[self flowColumnWidth],
                       (point.y - TOP_BLANK_SPACE_HEIGHT)/ROW_HEIGHT);
}

- (NSButtonCell*)cellCheckBox
{
    if (!_cellCheckBox) {
        _cellCheckBox = [[NSButtonCell alloc] init];
        [_cellCheckBox setTitle:@""];
        [_cellCheckBox setButtonType:NSSwitchButton];
        [_cellCheckBox setBordered:NO];
        [_cellCheckBox setImagePosition:NSImageLeft];
        [_cellCheckBox setAlignment:NSLeftTextAlignment];
        [_cellCheckBox setObjectValue:[NSNumber numberWithBool:NO]];
        [_cellCheckBox setControlSize:NSRegularControlSize];
        [_cellCheckBox setUsesSingleLineMode:YES];
        [_cellCheckBox setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return _cellCheckBox;
}

- (VerticallyCenteredTFCell *)cellTextfield
{
    if (!_cellTextfield) {
        _cellTextfield = [[VerticallyCenteredTFCell alloc] init];
        _cellTextfield.bordered = NO;
        _cellTextfield.alignment = NSLeftTextAlignment;
        _cellTextfield.controlSize = NSRegularControlSize;
        _cellTextfield.usesSingleLineMode = YES;
        _cellTextfield.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _cellTextfield;
}


- (NSMutableDictionary *)positions
{
    if (!_positions) {
        _positions = [[NSMutableDictionary alloc] init];
    }
    
    return _positions;
}

- (NSArray *)groupColors
{
    if (!_groupColors) {
        NSMutableArray *colors = [[NSMutableArray alloc] init];
        [colors addObject:[NSColor colorWithCalibratedRed:255/255.0 green:255/255.0 blue:11/255.0 alpha:1.0]];
        [colors addObject:[NSColor colorWithCalibratedRed:46/255.0 green:223/255.0 blue:32/255.0 alpha:1.0]];
        [colors addObject:[NSColor colorWithCalibratedRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
        _groupColors = [NSArray arrayWithArray:colors];
    }
    
    return _groupColors;
}

- (void)setTopConstraint:(NSLayoutConstraint *)topConstraint
{
    _topConstraint = topConstraint;
    _topConstraint.constant = 0.0;
}


- (void)setLeadingConstraint:(NSLayoutConstraint *)leadingConstraint
{
    _leadingConstraint = leadingConstraint;
    _leadingConstraint.constant = 0.0;
}

@end
