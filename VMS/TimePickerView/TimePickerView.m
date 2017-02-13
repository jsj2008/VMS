//
//  TimeScheduleView.m
//  VMS
//
//  Created by mac_dev on 15/6/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "TimePickerView.h"
//#define kCellWidth      14.0
#define kCellHeight     28.0
#define kCellsPerRow    48.0
#define kCellRows       7
#define kRowHeaderHeight   33.0
#define kColumnHeaderWidth 64.0


@interface TimePickerView() {
    BOOL _rowStates[7];
    BOOL _columnStates[48];
    BOOL _allState;
    long long _schedule[7];
}

@property (assign) NSPoint anchorLocation;
@property (assign) NSRect pickerZone;
@property (strong,nonatomic) NSButtonCell *cellCheckBox;//userd to draw column header checkbox
@property (strong,nonatomic) NSCursor *handCursor;
@end

@implementation TimePickerView

#pragma mark - public api

- (void)reloadData
{
    for (int row = 0; row < 7; row++)
        _rowStates[row] = NO;
    
    for (int col = 0; col < 48; col++)
        _columnStates[col] = NO;
    _allState = NO;
    
    [self setNeedsDisplay:YES];
}

- (void)setSchedule :(long long[7])schedule
{
    for (int i = 0; i < 7; i++) {
        _schedule[i] = schedule[i];
    }
    [self setNeedsDisplay:YES];
}

- (BOOL)getSchedule :(long long[]) schedule lenght :(NSUInteger)len
{
    if (len <= 7) {
        for (int i = 0; i < len; i++) {
            schedule[i] = _schedule[i];
        }
        
        return YES;
    }
    
    return NO;
}


#pragma mark - init
- (void)awakeFromNib
{
    [self adjustFrame];
}


- (void)adjustFrame
{
    NSSize pickerSize = NSMakeSize(kCellsPerRow * [self cellWidth], kCellRows * kCellHeight);
    [self setPickerZone:NSMakeRect(kColumnHeaderWidth,
                                   kRowHeaderHeight,
                                   pickerSize.width,
                                   pickerSize.height)];
    

    if (![self.constraints count]) {
        NSRect frame = self.frame;
        frame.size = NSMakeSize(pickerSize.width + kColumnHeaderWidth, pickerSize.height + kRowHeaderHeight);
        [self setFrame:frame];
    } else {
        NSDictionary *timePickerView = @{@"timePickerView":self};
        NSString *width = [NSString stringWithFormat:@"H:[timePickerView(%f)]",pickerSize.width + kColumnHeaderWidth];
        NSString *height = [NSString stringWithFormat:@"V:[timePickerView(%f)]",pickerSize.height + kRowHeaderHeight];
        NSString *xPos = [NSString stringWithFormat:@"H:|-0-[timePickerView]"];
        NSString *yPos = [NSString stringWithFormat:@"V:|-0-[timePickerView]"];
        
        //首先清除所有的约束条件
        [self removeConstraints:[self constraints]];
        //依次增加约束条件
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:width
                                                                     options:0
                                                                     metrics:nil
                                                                       views:timePickerView]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:height
                                                                     options:0
                                                                     metrics:nil
                                                                       views:timePickerView]];
        [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:xPos
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:timePickerView]];
        [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:yPos
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:timePickerView]];
    }
}

- (void)setupTrackingCursor
{
    [self addCursorRect:NSMakeRect(0, 0, self.bounds.size.width, kRowHeaderHeight) cursor:self.handCursor];
    [self addCursorRect:NSMakeRect(0, 0, kColumnHeaderWidth, self.bounds.size.height) cursor:self.handCursor];
    [self.handCursor setOnMouseEntered:YES];
}


#pragma mark - draw
- (void)drawLogoWithRect :(NSRect)rc
{
//    [[NSGraphicsContext currentContext] saveGraphicsState];
//    NSString    *name = _allState? @"PickAll On" : @"PickAll Off";
//    NSImage     *logo = [NSImage imageNamed:name];
//    [logo drawInRect:rc
//            fromRect:NSMakeRect(0, 0, logo.size.width, logo.size.height)
//           operation:NSCompositeSourceOver
//            fraction:1.0
//      respectFlipped:YES
//               hints:nil];
//    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSString    *allCheckText = NSLocalizedString(@"ALL", nil);
    NSFont      *columnHeaderTextFont   = [NSFont fontWithName:@"Helvetica Bold" size:12.0];
    NSColor     *columnHeaderTextColor  = [NSColor colorWithCalibratedWhite:0.322 alpha:1.000];
    NSDictionary*columnHeaderTextAtts  = [NSDictionary dictionaryWithObjectsAndKeys:
                                          columnHeaderTextFont,NSFontAttributeName,
                                          columnHeaderTextColor,NSForegroundColorAttributeName,nil];
    
    NSSize textSize = [allCheckText sizeWithAttributes:columnHeaderTextAtts];
    [allCheckText drawInRect:NSMakeRect(8, (kCellHeight - textSize.height) / 2.0, textSize.width, textSize.height)
              withAttributes:columnHeaderTextAtts];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}


- (void)drawRowHeaderWithRect :(NSRect)rc
{
    /*Draw row header
     *Draw background with black color
     *Draw title with white color
     *Draw title horizontal and vertical centering
     */
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSColor *rowHeaderColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:1];
    [rowHeaderColor set];
    NSRectFill(rc);
    
    NSFont  *rowHeaderTextFont      = [NSFont fontWithName:@"Helvetica Bold" size:13.0];
    NSColor *normalTextColor        = [NSColor whiteColor];
    NSColor *hightlightTextColor    = [NSColor colorWithRed:48/255.0 green:131/255.0 blue:251/255.0 alpha:1];
    NSDictionary *normalTextAtts    = [NSDictionary dictionaryWithObjectsAndKeys:
                                       rowHeaderTextFont,NSFontAttributeName,
                                       normalTextColor,NSForegroundColorAttributeName,nil];
    NSDictionary *highlightTextAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                                       rowHeaderTextFont,NSFontAttributeName,
                                       hightlightTextColor,NSForegroundColorAttributeName,nil];
    
    {
        NSString *title = NSLocalizedString(@"ALL", nil);
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
        NSDictionary *textAttrs = _allState?highlightTextAtts:normalTextAtts;
        
        [attrTitle setAttributes:textAttrs range:NSMakeRange(0, title.length)];
        NSSize titleSize = [title sizeWithAttributes:normalTextAtts];
        NSRect textRect = NSMakeRect((kColumnHeaderWidth  - titleSize.width)/2,
                                     (rc.size.height - titleSize.height)/2,
                                     titleSize.width,
                                     titleSize.height);
        [attrTitle drawInRect:textRect];
    }
    
    for (NSUInteger hour = 0; hour < 24; hour++) {
        NSString *title = [NSString stringWithFormat:@"%02ld",hour];
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
        NSDictionary *leftTextAttrs = _columnStates[2*hour]?highlightTextAtts:normalTextAtts;
        NSDictionary *rightTextAttrs = _columnStates[2*hour + 1]?highlightTextAtts:normalTextAtts;
        [attrTitle setAttributes:leftTextAttrs range:NSMakeRange(0, 1)];
        [attrTitle setAttributes:rightTextAttrs range:NSMakeRange(1, 1)];
        NSSize titleSize = [title sizeWithAttributes:normalTextAtts];
        NSRect textRect = NSMakeRect(kColumnHeaderWidth + rc.origin.x + hour * [self cellWidth] * 2 + (2 * [self cellWidth] - titleSize.width)/2,
                                     (rc.size.height - titleSize.height)/2,
                                     titleSize.width,
                                     titleSize.height);
        
        [attrTitle drawInRect:textRect];
    }
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}


- (void)drawUnSelectedCell
{
    //绿色(0.563,0.639,0.073,1.000)
    //灰色(0.960,0.960,0.960,1.000)
    //淡蓝色(0.439,0.784,0.901,1.000)
    //淡绿色(0.539,0.784,0.601,0.800)
    NSColor *unSelectedColor        = [NSColor colorWithCalibratedRed:0.539 green:0.784 blue:0.601 alpha:0.800];
    NSColor *unSelectedGridColor    = [NSColor colorWithCalibratedWhite:0.5 alpha:0.4];
    
    for (NSUInteger row = 0; row < kCellRows; row++) {
        for (NSUInteger column = 0; column < kCellsPerRow; column++) {
            long long value = 0x0000000000000001;
            value <<= column;
            
            if (!(_schedule[row] & value)) {
                [[NSGraphicsContext currentContext] saveGraphicsState];
                [unSelectedColor set];
                NSRectFill(NSMakeRect(kColumnHeaderWidth + column * [self cellWidth],
                                      kRowHeaderHeight + row * kCellHeight,
                                      [self cellWidth] + 1.0,
                                      kCellHeight + 1.0));
                
                //Draw selected grid line
                [unSelectedGridColor set];
                NSRectFillUsingOperation(NSMakeRect(kColumnHeaderWidth + column * [self cellWidth],
                                                    kRowHeaderHeight + row * kCellHeight,
                                                    1.0,
                                                    kCellHeight), NSCompositeSourceOver);
                NSRectFillUsingOperation(NSMakeRect(kColumnHeaderWidth + column * [self cellWidth],
                                                    kRowHeaderHeight + row * kCellHeight,
                                                    [self cellWidth], 1.0), NSCompositeSourceOver);
                [[NSGraphicsContext currentContext] restoreGraphicsState];
            }
        }
    }
}


- (void)drawImageBackgroundWithHeaderRect :(NSRect)rcHeader cellRect :(NSRect)rcCell
{
    //draw background
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"BGPattern"]] set];
    NSRectFill(rcHeader);
    
    [[NSColor redColor] set];
    NSRectFill(rcCell);
}

- (void)drawColumnHeaderText
{
    NSArray     *columnHeaderTexts      = nil;
    if (self.style == StartWithSunday) {
        columnHeaderTexts = @[@"星期日",@"星期一",@"星期二",@"星期三",@"星期四",@"星期五",@"星期六"];
    }
    else if (self.style == StartWithMonday) {
        columnHeaderTexts = @[@"星期一",@"星期二",@"星期三",@"星期四",@"星期五",@"星期六",@"星期日"];
    }
    
    if (columnHeaderTexts) {
        NSFont      *columnHeaderTextFont   = [NSFont fontWithName:@"Helvetica Bold" size:12.0];
        NSColor     *columnHeaderTextColor  = [NSColor colorWithCalibratedWhite:0.322 alpha:1.000];
        NSDictionary*columnHeaderTextAtts  = [NSDictionary dictionaryWithObjectsAndKeys:
                                              columnHeaderTextFont,NSFontAttributeName,
                                              columnHeaderTextColor,NSForegroundColorAttributeName,nil];
        
        for (NSUInteger row = 0; row < kCellRows; row++) {
            //Draw header in the center
            NSString *text = columnHeaderTexts[row];
            NSSize textSize = [text sizeWithAttributes:columnHeaderTextAtts];
            [text drawInRect:NSMakeRect(/*(kColumnHeaderWidth - textSize.width) / 2.0*/8,
                                        10.0 + row * kCellHeight + (kCellHeight - textSize.height) / 2.0,
                                        textSize.width, textSize.height)
              withAttributes:columnHeaderTextAtts];
        }
    }
}

- (void)drawGridLines
{
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
    
    for (NSUInteger row = 0; row < kCellRows; ++row)
        NSRectFill(NSMakeRect(0.0,
                              10.0 + row * kCellHeight,
                              kColumnHeaderWidth,
                              2.0));
    
    
    [[NSColor colorWithCalibratedWhite:0.678 alpha:1.0] set];
    for (NSUInteger row = 0; row < kCellRows; ++row)
        NSRectFill(NSMakeRect(0.0,
                              10.0 + row * kCellHeight,
                              kColumnHeaderWidth,
                              1.0));
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
    for (NSUInteger row = 0; row < kCellRows; ++row)
        NSRectFill(NSMakeRect(kColumnHeaderWidth,
                              10.0 + row * kCellHeight,
                              kCellsPerRow * [self cellWidth],
                              1.0));
    
    //Vertical direction
//    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
//    NSRectFill(NSMakeRect(- 1.0,10.0,3.0,kCellRows * kCellHeight));
//    for (NSUInteger col = 0; col < kCellsPerRow; ++col)
//        NSRectFill(NSMakeRect(kColumnHeaderWidth + col * [self cellWidth] - 1.0,
//                              10.0,
//                              3.0,
//                              kCellRows * kCellHeight));
    
    
    [[NSColor colorWithCalibratedWhite:0.678 alpha:1.000] set];
    NSRectFill(NSMakeRect(0,10.0,1.0,kCellRows * kCellHeight));
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
    //[[NSColor colorWithCalibratedRed:1.0 green:0 blue:0 alpha:0.2] set];
    for (NSUInteger col = 0; col < kCellsPerRow; ++col)
        NSRectFill(NSMakeRect(kColumnHeaderWidth + col * [self cellWidth],
                              10.0,
                              1.0,
                              kCellRows * kCellHeight));
}

- (void)eraseUnselectedCells
{
    [[NSColor clearColor] set];
    for (NSUInteger row = 0; row < kCellRows; row++) {
        //just erase the cells zone
        for (NSUInteger column = 0; column < kCellsPerRow; column++) {
            long long value = 0x0000000000000001;
            value <<= column;
            
            if (!(_schedule[row] & value)) {
                NSRectFill(NSMakeRect(kColumnHeaderWidth + column * [self cellWidth],
                                      10.0 + row * kCellHeight,
                                      [self cellWidth] + 1.0,
                                      kCellHeight + 1.0));
            }
        }
    }
}

- (void)drawShadow
{
    NSColor *shadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
    NSShadow *shadow = [[NSShadow alloc] init] ;
    
    [shadow setShadowColor:shadowColor];
    [shadow setShadowOffset:NSMakeSize(0.0, -3.0)];
    [shadow setShadowBlurRadius:4.0];
    [shadow set];
}

- (void)drawImage :(NSImage *)img withRect :(NSRect)rc
{
    if (img) {
        [img lockFocusFlipped:YES];
        //开始绘制
        [self drawImageBackgroundWithHeaderRect:NSMakeRect(rc.origin.x, rc.origin.y, kColumnHeaderWidth, rc.size.height)
                                       cellRect:NSMakeRect(rc.origin.x + kColumnHeaderWidth, rc.origin.y, rc.size.width - kColumnHeaderWidth, rc.size.height)];
        //[self drawImageBackgroundWithRect:rc];
        [self drawColumnHeaderText];
        [self drawGridLines];
        [self eraseUnselectedCells];
        //结束绘制
        [img unlockFocus];
    }
}

- (void)drawCheckbox
{
    for (NSUInteger row = 0;row < kCellRows; row++) {
        
        NSRect checkboxFrame = NSMakeRect(kColumnHeaderWidth - kCellHeight,
                                          kRowHeaderHeight + row*kCellHeight,
                                          kCellHeight,
                                          kCellHeight);
        [self.cellCheckBox setObjectValue:[NSNumber numberWithBool:_rowStates[row]]];
        [self.cellCheckBox drawWithFrame:checkboxFrame
                                  inView:self];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
   
    //Draw logo
    [self drawLogoWithRect:NSMakeRect(0, 0, kColumnHeaderWidth, kRowHeaderHeight)];
    [self drawRowHeaderWithRect:NSMakeRect(0,0,self.pickerZone.size.width + kColumnHeaderWidth,kRowHeaderHeight)];
    [self drawUnSelectedCell];
    
    //Draw the image
    NSRect  frame = NSMakeRect(0, kRowHeaderHeight, self.bounds.size.width, self.pickerZone.size.height);
    NSRect imageFrame = NSInsetRect(NSMakeRect(0, 0, frame.size.width, frame.size.height) , 0.0, -10.0);
    NSImage *tempImage = [[NSImage alloc] initWithSize:imageFrame.size];
    [self drawImage:tempImage withRect:imageFrame];

    [[NSGraphicsContext currentContext] saveGraphicsState];
    [self drawShadow];
    [tempImage drawInRect:frame
                 fromRect:NSOffsetRect(NSMakeRect(0, 0, frame.size.width, frame.size.height), 0.0, 10.0)
                operation:NSCompositeSourceOver
                 fraction:1.0
           respectFlipped:YES
                    hints:nil];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

#pragma mark - Action
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    NSPoint                     where    = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint                     location = [self pointToLocation:where];
    
    if (where.x > kColumnHeaderWidth && where.y > kRowHeaderHeight) {
        //单独选择某一个半小时
        NSUInteger row      = location.y;
        NSUInteger column   = location.x;
        
        [self setAnchorLocation:location];
        [self alterRow:row column:column];
    } else if (where.x > kColumnHeaderWidth && where.y  <= kRowHeaderHeight) {
        //一星期某一半小时
        NSUInteger column       = location.x;
        _columnStates[column]   = !_columnStates[column];
        
        [self setColumn:column state:_columnStates[column]];
    } else if (where.x <= kColumnHeaderWidth && where.y > kRowHeaderHeight) {
        NSUInteger row  = location.y;
        _rowStates[row] = !_rowStates[row];
       
        [self setRow:row state:_rowStates[row]];
    } else {
        _allState = !_allState;
        for (int i = 0; i < 7; i++) {
            _rowStates[i] = _allState;
        }
        for (int j = 0; j < 48; j++) {
            _columnStates[j] = _allState;
        }
        
        [self setState:_allState];
    }
    [self setNeedsDisplay:YES];
}



- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    NSPoint where = [self convertPoint:[theEvent locationInWindow]
                              fromView:nil];
    NSPoint location = [self pointToLocation:where];
    NSUInteger row = location.y;
    NSUInteger column = location.x;
    NSRect rc = self.bounds;
    NSRect validRc = NSMakeRect(kColumnHeaderWidth,
                                kRowHeaderHeight,
                                rc.size.width - kColumnHeaderWidth,
                                rc.size.height - kRowHeaderHeight);
    if (NSPointInRect(where, validRc)) {
        if ((row != (NSUInteger)self.anchorLocation.y) ||
            (column != (NSUInteger)self.anchorLocation.x)) {
            //判断是否是锚点
            if (row < 7 && column < 48) {
                [self setAnchorLocation:location];
                [self alterRow:row column:column];
            }
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)resetCursorRects
{
    [self discardCursorRects];
    [self addCursorRect:NSMakeRect(0, 0, self.bounds.size.width, kRowHeaderHeight)
                 cursor:self.handCursor];
    [self addCursorRect:NSMakeRect(0, 0, kColumnHeaderWidth, self.bounds.size.height) cursor:self.handCursor];
}


- (BOOL)isFlipped {return YES;};//翻转坐标系，使坐标原点落在左上角

- (NSPoint)pointToLocation :(NSPoint)where
{
    return NSMakePoint((where.x - kColumnHeaderWidth)/[self cellWidth],(where.y - kRowHeaderHeight)/kCellHeight);
}

#pragma mark - alter
- (void)alterRow :(NSUInteger)row column :(NSUInteger)col
{
    long long value = 0x0000000000000001;
    value <<= col;
    
    BOOL state = ((_schedule[row] & value) != 0x0000000000000000);
    _schedule[row] = !state? (_schedule[row] | value) : (_schedule[row] & ~value);
}

- (void)setColumn :(NSUInteger)col state :(BOOL)state
{
    long long value = 0x0000000000000001;
    value <<= col;
    for (int weekday = 0; weekday < 7; weekday++) {
        long long data = _schedule[weekday];
        _schedule[weekday] = state?(data | value) : (data & ~value);
        
    }
}

- (void)setRow :(NSUInteger)row state :(BOOL)state
{
    for (int halfHour = 0; halfHour < 48; halfHour++) {
        long long value = 0x0000000000000001;
        long long data = _schedule[row];
        value = value << halfHour;
        
        _schedule[row] = state? (data | value) : (data & ~value);
    }
}

- (void)setState :(BOOL)state
{
    for (int weekday = 0; weekday < 7; weekday++) {
        for (int halfHour = 0; halfHour < 48; halfHour++) {
            long long value = 0x0000000000000001;
            long long data = _schedule[weekday];
            value <<= halfHour;
            
            _schedule[weekday] = state? (data | value) : (data & ~value);
        }
    }
}
#pragma mark - setter and getter
- (NSButtonCell*)cellCheckBox
{
    if (!_cellCheckBox) {
        _cellCheckBox = [[NSButtonCell alloc] init];
        [_cellCheckBox setTitle:@""];
        [_cellCheckBox setButtonType:NSSwitchButton];
        [_cellCheckBox setBordered:NO];
        [_cellCheckBox setImagePosition:NSImageRight];
        [_cellCheckBox setAlignment:NSRightTextAlignment];
        [_cellCheckBox setObjectValue:[NSNumber numberWithBool:NO]];
        [_cellCheckBox setControlSize:NSRegularControlSize];
    }
    return _cellCheckBox;
}

- (NSCursor *)handCursor
{
    if (!_handCursor) {
        _handCursor = [NSCursor pointingHandCursor];
    }
    return _handCursor;
}

- (CGFloat)cellWidth
{
    return (self.bounds.size.width - kColumnHeaderWidth)/kCellsPerRow;
}

- (void)setStyle:(TPV_STYLE)style
{
    _style = style;
    [self setNeedsDisplay:YES];
}

@end
