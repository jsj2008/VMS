//
//  AmbaDetectComponentViewController.m
//  
//
//  Created by mac_dev on 16/4/5.
//
//

#import "AmbaDetectComponentViewController.h"

#define Leading     16.0
#define Trailing    8.0
#define Top         16.0
#define Bottom      8.0

@interface AmbaDetectComponentViewController ()
@property(readwrite) NSInteger index;

@property(nonatomic,weak) IBOutlet NSButton *validBtn;
@property(nonatomic,weak) IBOutlet NSTextField *captionTF;
@property(nonatomic,weak) IBOutlet NSPopUpButton *sensitivityBtn;

@end

@implementation AmbaDetectComponentViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                          index:(NSUInteger)index
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.index = index;
    }
    
    return self;
}

- (int)sensitivityFromUI
{
    return (int)self.sensitivityBtn.selectedTag;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


#pragma mark - setter && getter
- (void)setSensitivity:(int)sensitivity
{
    _sensitivity  = sensitivity;
    [_sensitivityBtn selectItemWithTag:_sensitivity];
}

- (void)setSensitivityBtn:(NSPopUpButton *)sensitivityBtn
{
    _sensitivityBtn = sensitivityBtn;
    [_sensitivityBtn selectItemWithTag:self.sensitivity];
}

- (void)setCaptionTF:(NSTextField *)captionTF
{
    _captionTF = captionTF;
    _captionTF.stringValue = [NSString stringWithFormat:@"%@%ld",NSLocalizedString(@"ZONE", nil),(self.index + 1)];
}


@end
