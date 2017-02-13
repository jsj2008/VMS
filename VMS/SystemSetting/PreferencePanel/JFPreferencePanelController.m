//
//  JFPreferencePanelController.m
//  JFPreferencePanel
//
//  Created by mac_dev on 2016/10/22.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferencePanelController.h"
#import "JFPreferenceRootViewController.h"

#define DEFAULT_WINDOW_WIDTH    450.0
#define DEFAULT_WINDOW_HEIGHT   300.0
#define ROW_ITEMS               5.0
#define ITEM_HEIGHT             100.0


@interface JFPreferencePanelController ()

@property(nonatomic,strong) JFPreferenceRootViewController *root;
@property(nonatomic,weak) JFPreferenceViewController *currentViewController;
@property(nonatomic,weak) IBOutlet NSSegmentedControl *segmentedControl;

@end

@implementation JFPreferencePanelController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupRootView];
    [self setCurrentViewController:self.root];
}

- (void)setupRootView
{
    if (!self.root) {
        //加载preference.plist文件,根据元素个数计算高度
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"preference" withExtension:@"plist"];
        NSArray *items = [NSArray arrayWithContentsOfURL:url];
        
        self.root = [[JFPreferenceRootViewController alloc] initWithNibName:@"JFPreferenceRootViewController" bundle:nil];
        self.root.items = items;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performToggleScene:self.root];
        });
        
    }
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
}

#pragma mark - toggle content view
- (void)performToggleScene :(JFPreferenceViewController *)pvc
{
    NSView *view = pvc.view;
    
    if (view && ([self.window contentView] != view)) {
        
        NSRect newFrame = [self.window frameRectForContentRect:[view bounds]];
        NSRect oldFrame = [self.window frame];
        
        newFrame.origin = oldFrame.origin;
        newFrame.origin.y -= (newFrame.size.height - oldFrame.size.height);
        
        [self.window setContentView:view];
        [self.window setFrame:newFrame display:YES animate:YES];
        [self setCurrentViewController:pvc];
    }
}

#pragma mark - preference view contrller delegate
- (void)preferencePanel:(JFPreferenceViewController *)src willForwardToPanel:(JFPreferenceViewController *)dest
{
    src.forwardController = dest;
    dest.backController = src;
    
    [self performToggleScene:dest];
}

- (void)preferencePanel:(JFPreferenceViewController *)src willBackToPanel:(JFPreferenceViewController *)dest
{
    dest.forwardController = nil;
    [self performToggleScene:dest];
}

#pragma mark - action
- (IBAction)toggleScene:(id)sender
{
    NSInteger selectedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:selectedSegment];
    
    switch (clickedSegmentTag) {
        case 0://back
            [self performToggleScene:self.currentViewController.backController];
            break;
            
        case 1://forward
            [self performToggleScene:self.currentViewController.forwardController];
            break;
        default:
            break;
    }
}

- (IBAction)backToHome:(id)sender
{
    if (self.currentViewController != self.root) {
        self.root.forwardController = nil;
        [self performToggleScene:self.root];
    }
}


#pragma mark - window delegate
- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModal];
}

#pragma mark - setter & getter
- (void)setCurrentViewController:(JFPreferenceViewController *)currentViewController
{
    _currentViewController = currentViewController;
    _currentViewController.delegate = self;
    [_currentViewController load];
    
    NSString *title = _currentViewController.panelTitle;
    self.window.title = title? title : @"Untitled";
    
    [self.segmentedControl setEnabled:_currentViewController.backController? YES : NO forSegment:0];
    [self.segmentedControl setEnabled:_currentViewController.forwardController? YES : NO forSegment:1];
}
@end
