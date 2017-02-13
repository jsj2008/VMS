//
//  JFCVPrototype.m
//  JFPreferencePanel
//
//  Created by Jeff on 16/10/23.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import "JFCVPrototype.h"


@interface JFCVPrototype ()

@end

@implementation JFCVPrototype

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)setRepresentedObject:(id)representedObject{
    [super setRepresentedObject:representedObject];
    if (representedObject !=nil)
    {
        //OSType code = UTGetOSTypeFromString((__bridge CFStringRef)[representedObject valueForKey:KEY_ICON]);
        //[self.itemButton setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)]];
        [self.itemButton setImage:[NSImage imageNamed:[representedObject valueForKey:KEY_ICON]]];
        [self.itemButton setTitle:NSLocalizedString([representedObject valueForKey:KEY_NAME], nil)];
        
        self.scene = [representedObject valueForKey:KEY_XIB];
        //[self.titleTextField setStringValue:[representedObject valueForKey:KEY_NAME]];
    }
}

- (IBAction)gotoCustomSettingView:(id)sender
{
    self.delegate = (id<JFCVPrototypeDelegate>)self.collectionView.delegate;
    
    if ([self.delegate respondsToSelector:@selector(cvPrototype:didClickedNotification:)]) {
        [self.delegate cvPrototype:self didClickedNotification:nil];
    }
}

@end
