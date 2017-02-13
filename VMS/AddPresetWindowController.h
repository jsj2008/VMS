//
//  AddPresetWindowController.h
//  VMS
//
//  Created by mac_dev on 2016/11/18.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AddPresetWindowController : NSWindowController

@property(nonatomic,copy) NSString *presetPointName;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
@end
