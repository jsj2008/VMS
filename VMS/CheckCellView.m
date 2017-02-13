//
//  CheckCellView.m
//  
//
//  Created by mac_dev on 16/6/14.
//
//

#import "CheckCellView.h"

@interface CheckCellView()
@property(nonatomic,weak) IBOutlet NSButton *checkBtn;
@end

@implementation CheckCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

#pragma mark - setter & getter
- (void)setHidden:(BOOL)hidden
{
    self.checkBtn.hidden = hidden;
}

- (BOOL)state
{
    return self.checkBtn.state == NSOnState;
}

- (void)setState:(BOOL)state
{
    self.checkBtn.state = state? NSOnState : NSOffState;
}

- (void)setTag:(NSInteger)tag
{
    self.checkBtn.tag = tag;
}
@end
