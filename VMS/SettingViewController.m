//
//  SettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()
@property(nonatomic,assign) int curChn;

@end

@implementation SettingViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    BOOL bChnHide = self.device.channelCount < 2;
    self.chnLabel.hidden = bChnHide;
    self.chnBtn.hidden = bChnHide;
}
- (void)viewWillAppear
{
    [super viewWillAppear];
}
#pragma mark - public api
- (void)fetch
{
    //更新当前model
    FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:self.curChn];
    self.model = ability.model;
}

- (void)push
{}

- (NSString *)description
{
    return @"";
}

- (void)refetch :(NSInteger)tag
{
    //Implement by sub class.
}

- (void)push :(NSInteger)tag
{
   //Implement by sub class.
}

- (void)alert:(NSString *)msg info:(NSString *)info
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert setMessageText:msg];
    [alert setInformativeText :info];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
}

- (NSString *)safetyText :(NSString *)string
{
    return !string? @"" : string;
}

- (NSArray *)channels
{
    NSMutableArray *channels = [[NSMutableArray alloc] init];
    for (int chn = 0; chn < self.device.channelCount; chn++) {
        [channels addObject:[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"Channel", nil),chn + 1]];
    }
    
    return [NSArray arrayWithArray:channels];
}

#pragma mark - action
- (IBAction)save:(id)sender
{
    NSTabViewItem *item = [self.tabView selectedTabViewItem];
    NSInteger index = [self.tabView indexOfTabViewItem:item];
    [self push :index];
}

- (IBAction)refresh :(id)sender
{
    
    NSTabViewItem *item = [self.tabView selectedTabViewItem];
    NSInteger index = [self.tabView indexOfTabViewItem:item];
    [self refetch :index];
}

- (IBAction)chnOption:(id)sender
{
    if (self.curChn != self.chn) {
        self.curChn = self.chn;
        [self fetch];
    }
}
#pragma mark - tabview delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [self refetch:index];
}

- (void)setActivity:(BOOL)activity
{
    id<SVCDelegate> delegate = self.delegate;
    
    if (delegate) {
        if (activity) {
            if ([delegate respondsToSelector:@selector(svc:willFetch:)]) {
                [delegate svc:self willFetch:nil];
            }
        } else {
            if ([delegate respondsToSelector:@selector(svc:didFetch:)]) {
                [delegate svc:self didFetch:nil];
            }
        }
    }
}

- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range
{
    [btn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2d",(int)range.location + i];
        [btn addItemWithTitle:title];
    }
}

- (void)setControl :(NSPopUpButton *)btn withTitles :(NSArray *)titles
{
    [btn removeAllItems];
    for (int i = 0; i < titles.count; i++) {
        NSString *title = titles[i];
        [btn addItemWithTitle:title];
    }
}

- (void)setChnBtn:(NSPopUpButton *)chnBtn
{
    _chnBtn = chnBtn;
    
    NSMutableArray *chnNames = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.device.channelCount;i++) {
        [chnNames addObject:[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"Channel", nil),i + 1]];
    }
    [self setControl:_chnBtn withTitles:chnNames];
}
@end
