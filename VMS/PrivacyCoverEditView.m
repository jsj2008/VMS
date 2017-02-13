//
//  PrivacyCoverEditView.m
//  
//
//  Created by mac_dev on 16/3/29.
//
//

#import "PrivacyCoverEditView.h"


#define MIN_AREA_WIDTH  12
#define BORDER_WIDTH    1
#define MRW   12
#define BORDER_COLOR_NOT_SELECTED       [NSColor yellowColor]
#define BORDER_COLOR_SELECTED           [NSColor blueColor]
#define RECT_FILL_COLOR                 [[NSColor redColor] colorWithAlphaComponent:0.4]
#define SELECTED_AREA_DID_CHANGE        @"selected area did change"




@implementation Anchor
- (instancetype)initWithLocation:(NSPoint)location rect:(NSRect)rc operation:(DRAG_OP)op
{
    if (self = [super init]) {
        self.location = location;
        self.rc = rc;
        self.op = op;
    }
    
    return self;
}

- (NSRect)rectFromPoint :(NSPoint)pt1 andPoint :(NSPoint)pt2
{
    return NSMakeRect(MIN(pt1.x, pt2.x), MIN(pt1.y, pt2.y), fabs(pt1.x - pt2.x), fabs(pt1.y - pt2.y));
}

- (NSRect)modifyToLocation :(NSPoint)location
{
    NSPoint pt1,pt2;
    CGFloat detX = location.x - self.location.x;
    CGFloat detY = location.y - self.location.y;
    
    switch (self.op) {
        case DRAG_MODIFY_LB: {
            pt1 = self.rc.origin;
            pt2 = NSMakePoint(pt1.x + self.rc.size.width, pt1.y + self.rc.size.height);
            
            pt1.x += detX;
            pt1.y += detY;
            
            if (pt2.x - pt1.x < MIN_AREA_WIDTH) {
                pt1.x = pt2.x - MIN_AREA_WIDTH;
            }
            
            if (pt2.y - pt1.y < MIN_AREA_WIDTH) {
                pt1.y = pt2.y - MIN_AREA_WIDTH;
            }
        }
            break;
            
        case DRAG_MODIFY_RB: {
            pt1 = NSMakePoint(self.rc.origin.x + self.rc.size.width, self.rc.origin.y);
            pt2 = NSMakePoint(self.rc.origin.x, self.rc.origin.y + self.rc.size.height);
            pt1.x += detX;
            pt1.y += detY;
            
            if (pt1.x - pt2.x < MIN_AREA_WIDTH) {
                pt1.x = pt2.x + MIN_AREA_WIDTH;
            }
            
            if (pt2.y - pt1.y < MIN_AREA_WIDTH) {
                pt1.y = pt2.y - MIN_AREA_WIDTH;
            }
        }
            break;
            
        case DRAG_MODIFY_RT: {
            pt2 = self.rc.origin;
            pt1 = NSMakePoint(pt2.x + self.rc.size.width, pt2.y + self.rc.size.height);
            pt1.x += detX;
            pt1.y += detY;
            
            if (pt1.x - pt2.x < MIN_AREA_WIDTH) {
                pt1.x = pt2.x + MIN_AREA_WIDTH;
            }
            
            if (pt1.y - pt2.y < MIN_AREA_WIDTH) {
                pt1.y = pt2.y + MIN_AREA_WIDTH;
            }
        }
            break;
            
        case DRAG_MODIFY_LT: {
            pt1 = NSMakePoint(self.rc.origin.x, self.rc.origin.y + self.rc.size.height);
            pt2 = NSMakePoint(self.rc.origin.x + self.rc.size.width, self.rc.origin.y);
            pt1.x += detX;
            pt1.y += detY;
            
            if (pt2.x - pt1.x < MIN_AREA_WIDTH) {
                pt1.x = pt2.x - MIN_AREA_WIDTH;
            }
            
            if (pt1.y - pt2.y < MIN_AREA_WIDTH) {
                pt1.y = pt2.y + MIN_AREA_WIDTH;
            }
        }
            break;
            
        case DRAG_MOVE: {
            pt1 = self.rc.origin;
            pt2 = NSMakePoint(pt1.x + self.rc.size.width, pt1.y + self.rc.size.height);
            pt1.x += detX;
            pt1.y += detY;
            pt2.x += detX;
            pt2.y += detY;
        }
            break;
            
        case DRAG_CREATE:
        default: {
            pt1 = self.location;
            pt2 = location;
        }
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(clipRect:opration:)])
        return [self.delegate clipRect:[self rectFromPoint:pt1 andPoint:pt2] opration:self.op];
    
    return [self rectFromPoint:pt1 andPoint:pt2];
}
@end


////////////////////////////////////////////////////////////////////////////////
@interface PrivacyCoverEditView()

@property(nonatomic,strong) NSMutableArray *areas;
@property(readwrite) NSInteger indexOfSelectedArea;
@property(nonatomic,assign) NSRect newRect;
@property(nonatomic,strong) Anchor *anchor;
@end

@implementation PrivacyCoverEditView
#pragma mark - init
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        self.indexOfSelectedArea = NSNotFound;
        self.newRect = NSZeroRect;
        self.wantsLayer = YES;
        self.rcCountLimit = 3;
    }
    
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.indexOfSelectedArea = NSNotFound;
    }
    
    return self;
}

- (instancetype)initWithFrame :(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.indexOfSelectedArea = NSNotFound;
    }
    
    return self;
}

#pragma mark - public api
- (void)selectAreaAtIndex :(NSInteger)index
{
    self.indexOfSelectedArea = (index < self.areas.count)? index : NSNotFound;
    [self setNeedsDisplay:YES];
}

//这里移除指定index的矩形，以NSZeroRect替代原有的
- (void)removeAreaAtIndex :(NSInteger)index
{
    if (index < self.areas.count) {
        [self.areas replaceObjectAtIndex:index withObject:[NSValue valueWithRect:NSZeroRect]];
        [self setIndexOfSelectedArea:[self indexOfNextSelectArea]];
        [self setNeedsDisplay:YES];
    }
}

- (void)addArea :(NSRect)rc
{
    if (self.areas.count < self.rcCountLimit) {
        [self.areas addObject:[NSValue valueWithRect:[self rectFromTexture:[self clipTexture:rc]]]];
        [self setNeedsDisplay:YES];
    }
}

- (NSArray *)allAreas
{
    NSMutableArray *allAreas = [[NSMutableArray alloc] init];
    
    for (NSValue *area in self.areas) {
        NSRect rcOrigin = [area rectValue];
        NSRect rc = [self isValidRect:rcOrigin]? rcOrigin : NSZeroRect;
        [allAreas addObject:[NSValue valueWithRect:[self rectToTexture:rc]]];
    }
    
    return [NSArray arrayWithArray:allAreas];
}

#pragma mark - private method
- (CGFloat)validTextureValue :(CGFloat)val
{
    if (val < 0.0) {
        val = 0.0;
    }
    
    if (val > 1.0) {
        val = 1.0;
    }
    
    return val;
}

- (NSRect)clipTexture :(NSRect)texture
{
    return NSMakeRect([self validTextureValue:texture.origin.x],
                      [self validTextureValue:texture.origin.y],
                      [self validTextureValue:texture.size.width],
                      [self validTextureValue:texture.size.height]);
}

- (NSRect)dragRectInRect :(NSRect)rc withOpration :(DRAG_OP)op
{
    if (![self isValidRect :rc])
        return NSZeroRect;
    
    CGFloat x = rc.origin.x;
    CGFloat y = rc.origin.y;
    CGFloat w = rc.size.width;
    CGFloat h = rc.size.height;
    
    switch (op) {
        case DRAG_MODIFY_LB:
            return NSMakeRect(x, y, MRW, MRW);
        case DRAG_MODIFY_RB:
            return NSMakeRect(x - MRW + w, y, MRW, MRW);
        case DRAG_MODIFY_RT:
            return NSMakeRect(x - MRW + w, y - MRW + h, MRW, MRW);
        case DRAG_MODIFY_LT:
            return NSMakeRect(x, y - MRW + h, MRW, MRW);
        case DRAG_MOVE:
            return rc;
        case DRAG_NONE:
        default:
            return NSZeroRect;
    }
}

- (DRAG_OP)operationInRect :(NSRect)rc withPoint :(NSPoint)pt
{
    if (NSIsEmptyRect(rc))
        return DRAG_CREATE;
    
    DRAG_OP ops[5] = {DRAG_MODIFY_LB,DRAG_MODIFY_RB,DRAG_MODIFY_RT,DRAG_MODIFY_LT,DRAG_MOVE};
    for (int i = 0; i < 5; i++) {
        DRAG_OP op = ops[i];
        NSRect dragRect = [self dragRectInRect:rc withOpration:op];
        
        if (NSPointInRect(pt, dragRect))
            return op;
    }
    
    return DRAG_NONE;
}

//该方法，返回View里面的任意的点，多对应的区域索引，及操作
- (NSInteger)indexOfAreaForPoint :(NSPoint)point
{
    NSInteger count = self.areas.count;
    NSInteger index = NSNotFound;
    
    for (NSInteger i = 0; i < count; i++) {
        NSRect rc = [[self.areas objectAtIndex:i] rectValue];
        if (NSPointInRect(point, rc)) {
            index = i;
        }
    }
    
    return index;
}

- (BOOL)equalRect :(NSRect)aRect and :(NSRect)bRect
{
    return fabs(aRect.origin.x - bRect.origin.x) < 0.000001 &&
    fabs(aRect.origin.y - bRect.origin.y) < 0.000001 &&
    fabs(aRect.size.width - bRect.size.width) < 0.000001 &&
    fabs(aRect.size.height - bRect.size.height) < 0.000001;
}

- (BOOL)isValidRect :(NSRect)rc
{
    if (rc.size.width < MIN_AREA_WIDTH || rc.size.height < MIN_AREA_WIDTH) {
        NSLog(@"形状受限");
        return NO;
    }

    if (![self equalRect:rc and:NSIntersectionRect(rc, self.bounds)]) {
        NSLog(@"越界");
        return NO;
    }
    
    return YES;
}

- (BOOL)creatable
{
    for (NSValue *rcVal in self.areas) {
        if (NSIsEmptyRect([rcVal rectValue])) {
            return YES;
        }
    }
    
    return self.areas.count < self.rcCountLimit;
}

- (NSInteger)indexOfNextSelectArea
{
    NSInteger indexOfSelectArea = self.indexOfSelectedArea;
    NSInteger count = self.areas.count;
    
    if (indexOfSelectArea == NSNotFound)
        return NSNotFound;
    
    for (NSInteger i = 1; i < count; i++) {
        NSInteger index = (i + indexOfSelectArea) % count;
        if (!NSIsEmptyRect([self.areas[index] rectValue])) {
            return index;
        }
    }
    
    return NSNotFound;
}
//纹理坐标系为0-1
- (NSRect)rectFromTexture :(NSRect)rc
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    return NSIsEmptyRect(rc)? NSZeroRect : NSMakeRect(rc.origin.x * w, rc.origin.y * h, rc.size.width * w, rc.size.height * h);
}

- (NSRect)rectToTexture :(NSRect)rc
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    return NSIsEmptyRect(rc)? NSZeroRect : NSMakeRect(rc.origin.x / w, rc.origin.y / h, rc.size.width / w, rc.size.height / h);
}

#pragma mark - draw
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawRectangles:self.areas withSelectedIndex:self.indexOfSelectedArea];
    [self drawBound];
}

- (void)drawBound
{
    [[NSColor yellowColor] set];
    NSFrameRectWithWidthUsingOperation(self.bounds, 2, NSCompositeSourceOver);
}

- (void)drawDragAreaInRect :(NSRect)rc
{
    DRAG_OP ops[4] = {DRAG_MODIFY_LB,DRAG_MODIFY_RB,DRAG_MODIFY_RT,DRAG_MODIFY_LT};
    
    for (int i = 0; i < 4; i++) {
        NSRect dragRect = [self dragRectInRect:rc withOpration:ops[i]];
        NSFrameRectWithWidthUsingOperation(dragRect, BORDER_WIDTH, NSCompositeSourceOver);
    }
}

- (void)fillRectangles :(NSArray *)rects
{
    [RECT_FILL_COLOR set];
    for (NSValue *rcVal in rects)
        NSRectFill(rcVal.rectValue);
}

- (void)borderRectangles :(NSArray *)rects
{
    NSInteger count = rects.count;
    NSInteger selectedIdx = self.indexOfSelectedArea;
    //填充矩形框
    for (NSInteger idx = 0; idx < count; idx++) {
        NSRect rc = [[rects objectAtIndex:idx] rectValue];
        [((idx == selectedIdx)? BORDER_COLOR_SELECTED : BORDER_COLOR_NOT_SELECTED) set];
        NSFrameRectWithWidthUsingOperation(rc, BORDER_WIDTH, NSCompositeSourceOver);
        [self drawDragAreaInRect:rc];
    }
}

- (void)indexRectangles :(NSArray *)rects
{
    NSInteger count = rects.count;
    
    for (NSInteger idx = 0; idx < count; idx++) {
        [[NSColor whiteColor] set];
        NSRect rc = [[rects objectAtIndex:idx] rectValue];
        if (!NSIsEmptyRect(rc)) {
            NSRectFill([self dragRectInRect:rc withOpration:DRAG_MODIFY_LT]);
            [[NSString stringWithFormat:@"%ld",idx + 1] drawInRect:NSOffsetRect(rc, 2, 2) withAttributes:nil];
        }
    }
}

- (void)drawRectangles :(NSArray *)rects withSelectedIndex :(NSInteger)selectedIdx
{
    [self fillRectangles:rects];
    [self borderRectangles:rects];
    
    if (self.needDisplayIndex)
        [self indexRectangles:rects];

    if (!NSIsEmptyRect(self.newRect)) {
        [RECT_FILL_COLOR set];
        NSRectFill(self.newRect);
        [BORDER_COLOR_SELECTED set];
        NSFrameRectWithWidthUsingOperation(self.newRect, BORDER_WIDTH, NSCompositeSourceOver);
    }
}

#pragma mark - anchor clip delegate
- (NSRect)clipRect :(NSRect)rc opration :(DRAG_OP)op
{
    NSRect bound = self.bounds;

    if (![self equalRect:rc and:NSIntersectionRect(rc, bound)]) {
        switch (op) {
            case DRAG_MOVE: {
                CGFloat x = rc.origin.x;
                CGFloat y = rc.origin.y;
                CGFloat w = rc.size.width;
                CGFloat h = rc.size.height;
                CGFloat dx = (x < 0)?(0 - x) : ((x <= bound.size.width - w)? 0 : bound.size.width - x - w);
                CGFloat dy = (y < 0)?(0 - y) : ((y <= bound.size.height - h)? 0 : bound.size.height - y - h);
                return NSOffsetRect(rc, dx, dy);
            }
            case DRAG_CREATE:
            case DRAG_MODIFY_LB:
            case DRAG_MODIFY_LT:
            case DRAG_MODIFY_RB:
            case DRAG_MODIFY_RT:
            default:
                return NSIntersectionRect(rc, bound);
        }
    }
    
    return rc;
}


#pragma mark - event
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    NSPoint     location = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSInteger   index = [self indexOfAreaForPoint:location];
    
    if (index != self.indexOfSelectedArea) {
        self.indexOfSelectedArea = index;
        //self.anchor = location;
        
        if ([self.delegate respondsToSelector:@selector(selectedAreaDidChange:)]) {
            [self.delegate selectedAreaDidChange:[NSNotification notificationWithName:SELECTED_AREA_DID_CHANGE object:self]];
        }
    }
    
    [self setNeedsDisplay:YES];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    
    NSPoint location = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSInteger indexOfSelectedArea = self.indexOfSelectedArea;
    
    //抛锚
    if (!self.anchor) {
        NSRect rc = (indexOfSelectedArea == NSNotFound)? NSZeroRect : [[self.areas objectAtIndex:indexOfSelectedArea] rectValue];
        DRAG_OP op = [self operationInRect:rc withPoint:location];
        self.anchor = [[Anchor alloc] initWithLocation:location rect:rc operation:op];
        self.anchor.delegate = self;
    }
    
    //移动
    NSRect newRect = [self.anchor modifyToLocation:location];
    if (indexOfSelectedArea != NSNotFound)
        [self.areas replaceObjectAtIndex:indexOfSelectedArea withObject:[NSValue valueWithRect:newRect]];
    else if ([self creatable])
        [self setNewRect:newRect];

    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    //查看是否新增矩形
    NSInteger count = self.areas.count;
    NSInteger indexOfSelectedAreaOld = self.indexOfSelectedArea;
    BOOL success = NO;
    if ([self isValidRect:self.newRect]) {
        //查看面积数组里是否有empty rect
        for (NSInteger index = 0; index < count;index++ ) {
            if (NSIsEmptyRect([self.areas[index] rectValue])) {
                [self.areas replaceObjectAtIndex:index withObject:[NSValue valueWithRect:self.newRect]];
                self.indexOfSelectedArea = index;
                success = YES;
                break;
            }
        }
        
        //查看数组长度是否达到矩形数量上限
        if (!success && count < self.rcCountLimit) {
            [self.areas addObject:[NSValue valueWithRect:self.newRect]];
            self.indexOfSelectedArea = count + 1;
        }
        
        //查看选中是否发生改变
        if ((indexOfSelectedAreaOld != self.indexOfSelectedArea) &&
            [self.delegate respondsToSelector:@selector(selectedAreaDidChange:)]) {
            [self.delegate selectedAreaDidChange:[NSNotification notificationWithName:SELECTED_AREA_DID_CHANGE object:self]];
        }
    }
    
    //收锚
    self.anchor = nil;
    self.newRect = NSZeroRect;
    
    [self setNeedsDisplay:YES];
}
#pragma mark - setter && getter
- (NSMutableArray *)areas
{
    if (!_areas) {
        _areas = [[NSMutableArray alloc] init];
    }
    
    return _areas;
}


@end
