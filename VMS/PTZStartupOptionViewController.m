//
//  PTZStartupOptionViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "PTZStartupOptionViewController.h"

@interface PTZStartupOptionViewController ()

@property(nonatomic,weak) IBOutlet NSPopUpButton *startUpOptionsBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *presetOptionBtn;
@property(nonatomic,assign,getter=isHidePresetOption) BOOL hidePresetOption;

@end

@implementation PTZStartupOptionViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG config;
        //获取自检模式和自检模式预制位.
        int     mode = 0;
        char    name[FOS_MAX_PRESETPOINT_NAME_LEN];
        FOS_RESETPOINTLIST pts;
    
        memset(name, 0, FOS_MAX_PRESETPOINT_NAME_LEN);
        memset(&pts, 0, sizeof(FOS_RESETPOINTLIST));
        
        void *infos[] = {
            &mode,
            &name,
            &pts
        };
        
        FOSCAM_NET_CONFIG_TYPE types[] = {
            FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE,
            FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME,
            FOSCAM_NET_CONFIG_PTZ_PRESET_POINT_LIST
        };
        
        BOOL    success = YES;
        for (int i = 0; (i < 3) && success; i++) {
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }
        
        NSString *ptName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setSelfTestMode:mode];
                [self setPresetPointList:pts];
                [self setSelfTestPresetName:ptName];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
           
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG   config;
        NSInteger           option = [self.startUpOptionsBtn selectedTag];
        BOOL                success = NO;
        
        //保存自启动模式
        config.info = &option;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE
                                                    toDevice:self.device]) {
            success = YES;
            //是否需要保存自启动预置点
            if (option == 2) {
                char name[FOS_MAX_PRESETPOINT_NAME_LEN] = {0};
                if ([[self.presetOptionBtn titleOfSelectedItem] getCString:name
                                                                 maxLength:FOS_MAX_PRESETPOINT_NAME_LEN
                                                                  encoding:NSASCIIStringEncoding]) {
                    config.info = name;
                    success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                       forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME
                                                                      toDevice:self.device];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Start-Up Options", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

#pragma mark - action
- (IBAction)startOptionButtonAction:(id)sender
{
    NSPopUpButton *startUpOptionBtn = sender;
    NSInteger  idxOfSelectedItem = startUpOptionBtn.indexOfSelectedItem;
    self.hidePresetOption = (2 == idxOfSelectedItem);
}

#pragma mark - update UI
- (void)updateStartUpModeUI
{
    [self.startUpOptionsBtn selectItemWithTag:self.selfTestMode];
    self.hidePresetOption = (2 == self.startUpOptionsBtn.indexOfSelectedItem);
}

- (void)updateStartUpPresetUI
{
    [self.presetOptionBtn removeAllItems];
    
    NSInteger index = NSNotFound;
    for (int i = 0; i < self.presetPointList.pointCnt; i++) {
        NSString *title = [NSString stringWithCString:self.presetPointList.pointName[i]
                                             encoding:NSASCIIStringEncoding];
        [self.presetOptionBtn addItemWithTitle:title];
        
        //查找是否包含该预置点
        if (![self.selfTestPresetName isEqualToString:@""] &&
             [self.selfTestPresetName isEqualToString:title]) {
            index = i;
        }
    }
    
    if (index != NSNotFound) {
        [self.presetOptionBtn selectItemAtIndex:index];
    }
}

#pragma mark - data
- (NSArray *)availableSelfTestMode
{
    return @[NSLocalizedString(@"Disable Start-Up", nil),
             NSLocalizedString(@"Go to home position", nil),
             NSLocalizedString(@"Go to preset position", nil)];
}

#pragma mark - setter && getter
- (void)setSelfTestMode:(int)selfTestMode
{
    _selfTestMode = selfTestMode;
    [self updateStartUpModeUI];
}

- (void)setSelfTestPresetName:(NSString *)selfTestPresetName
{
    _selfTestPresetName = selfTestPresetName;
    [self updateStartUpPresetUI];
}

- (void)setStartUpOptionsBtn:(NSPopUpButton *)startUpOptionsBtn
{
    _startUpOptionsBtn = startUpOptionsBtn;
    [self setControl:_startUpOptionsBtn withTitles:[self availableSelfTestMode]];
    for (int tag = 0; tag < [self availableSelfTestMode].count; tag++) {
        [_startUpOptionsBtn itemAtIndex:tag].tag = tag;
    }
}

@end
