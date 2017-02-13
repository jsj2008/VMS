//
//  SettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DispatchCenter.h"
#import "../RegexKit/RegexKit/RegexKitLite.h"
#import "XMLHelper.h"

#define OUT_BUFFER_LENGTH   1024
#define EMPTY_CHANNEL   @"该通道缺少IPC或者不支持隐私遮盖"
#define KEY_RELOAD_WAIT_TIME    @"reload wait time"
#define DEBUG_CGI               1
#define KEY_REBOOT_NOTIFICATION     @"reboot"
#define KEY_RESTORE_NOTIFICATION    @"restore to factory"

@protocol SVCDelegate <NSObject>

- (void)svc :(NSViewController *)svc deviceInfoDidChange :(NSNotification *)aNotific;
- (void)svc :(NSViewController *)svc willFetch :(NSNotification *)aNotific;
- (void)svc :(NSViewController *)svc didFetch :(NSNotification *)aNotific;

@end

typedef NS_OPTIONS(NSUInteger, SVC_OPTION) {
    SVC_REFRESH = 1 << 0,
    SVC_SAVE = 1 << 1,
};

@interface SettingViewController : NSViewController<NSTabViewDelegate>

@property (nonatomic,assign) IBOutlet id<SVCDelegate> delegate;
@property (nonatomic,strong) CDevice *device;
@property (nonatomic,assign) FOSSTREAM_TYPE streamType;
@property (weak) IBOutlet NSTabView *tabView;
@property (nonatomic,assign) BOOL activity;
@property (nonatomic,assign,readonly) SVC_OPTION option;
@property (nonatomic,weak) IBOutlet NSTextField *chnLabel;
@property (nonatomic,weak) IBOutlet NSPopUpButton *chnBtn;
@property (nonatomic,assign) int chn;
@property (nonatomic,assign) int model;

- (void)fetch;
- (void)push;
- (NSString *)description;

- (void)alert:(NSString *)msg info:(NSString *)info;
- (NSString *)safetyText :(NSString *)string;
- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range;
- (void)setControl :(NSPopUpButton *)btn withTitles :(NSArray *)titles;
- (NSArray *)channels;

- (void)push :(NSInteger)tag;
- (void)refetch :(NSInteger)tag;
- (IBAction)save :(id)sender;
- (IBAction)refresh :(id)sender;
- (IBAction)chnOption:(id)sender;
@end
