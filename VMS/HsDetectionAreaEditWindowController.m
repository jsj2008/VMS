//
//  HsDetectionAreaEditWindowController.m
//  
//
//  Created by mac_dev on 16/4/5.
//
//

#import "HsDetectionAreaEditWindowController.h"

@interface HsDetectionAreaEditWindowController ()
@property (nonatomic,assign) BOOL outsideDetectEnable;
@property (nonatomic,strong) NSMutableArray *areas;
@end

@implementation HsDetectionAreaEditWindowController

#pragma mark - public api
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)channelId
                         detectConfig:(FOS_MOTIONDETECTCONFIG)config
{
    if (self = [super initWithWindowNibName:windowNibName channelId:channelId]) {
        _detectConfig = config;
        
        NSMutableArray *areas = [[NSMutableArray alloc] init];
        for (int i = 0; i < FOS_MAX_AREA_COUNT; i++)
            [areas addObject:[NSNumber numberWithInt:_detectConfig.areas[i]]];
        
        
        [self setAreas:areas];
    }
    
    return self;
}

- (void *)detectConfig
{
    return &_detectConfig;
}

- (void)preDone
{
    //更新MotionDetectConfig
    for (int i = 0; i < FOS_MAX_AREA_COUNT; i++) {
        NSNumber *area = [self.areas objectAtIndex:i];
        _detectConfig.areas[i] = area.intValue;
    }
    NSLog(@"Stop");
}

#pragma mark - area edit view delegate
- (BOOL)editView :(NSView *)view
shouldCoverAtRow :(int)row
          column :(int)col
{
    NSArray *areas = self.areas;
    int area = [[areas objectAtIndex :row] intValue];
    int origin = 0x00000001;
    
    return ((origin << col) & area) != 0x00000000;
}

- (void)alterCoverFromRowStart :(int)rStart
                      colStart :(int)cStart
                      toRowEnd :(int)rEnd
                        colEnd :(int)cEnd
                      editView :(NSView *)view
{
    BOOL outsideDetectEnable = self.outsideDetectEnable;
    
    for (int row = 0; row < ROWS; row++) {
        for (int col = 0; col < COLS; col++) {
            NSNumber *area = [self.areas objectAtIndex :row];
            int area_int = [area intValue];
            int origin = 0x00000001 << col;
            
            if (row >= rStart &&
                row <= rEnd &&
                col >= cStart &&
                col <= cEnd) {
                BOOL state = outsideDetectEnable? YES : (area_int & origin) != 0x00000000;
                area_int = state? (area_int & ~origin) : area_int | origin;
                
            } else if (outsideDetectEnable) {
                area_int = area_int | origin;
            }
            
            [self.areas replaceObjectAtIndex:row withObject:[NSNumber numberWithInt :area_int]];
        }
    }
    
    [self.renderView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setNeedsDisplay :YES];
    }];
}

#pragma mark - setter && getter
- (NSMutableArray *)areas
{
    if (!_areas) {
        _areas = [[NSMutableArray alloc] initWithObjects:@512,@512,@512,@512,@512,@512,@512,@512,@512,@512, nil];
    }
    
    return _areas;
}

@end
