//
//  AddPresetWindowController.m
//  VMS
//
//  Created by mac_dev on 2016/11/18.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "AddPresetWindowController.h"

@interface AddPresetWindowController ()

@property(nonatomic,weak) IBOutlet NSTextField *tf;
@property(nonatomic,assign) BOOL exitable;

@end

@implementation AddPresetWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
}


- (IBAction)done:(id)sender
{
    
    if ([self.tf.stringValue isEqualToString:@""]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.alertStyle = NSAlertStyleWarning;
        alert.messageText = NSLocalizedString(@"Preset name can not be empty! Please re-enter", nil);
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
        return;
    }
    
    self.presetPointName = self.tf.stringValue;
    self.exitable = YES;
    [NSApp stopModalWithCode:NSModalResponseOK];
}


- (IBAction)cancel:(id)sender
{
    self.exitable = YES;
    [NSApp stopModalWithCode:NSModalResponseCancel];
}

- (void)dealloc
{
    assert(self.exitable);
    
    if (!self.exitable) {
        NSLog(@"app will exit due to unexpect value AddPresetWindowController::exitable");
        exit(0);
    }
}

@end
