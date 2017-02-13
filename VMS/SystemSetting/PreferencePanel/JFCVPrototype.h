//
//  JFCVPrototype.h
//  JFPreferencePanel
//
//  Created by Jeff on 16/10/23.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define KEY_NAME    @"name"
#define KEY_ICON    @"icon"
#define KEY_XIB     @"xib"



@protocol JFCVPrototypeDelegate <NSCollectionViewDelegate>

@optional
- (void)cvPrototype:(NSCollectionViewItem *)item didClickedNotification :(NSNotification *)aNotific;
@end


@interface JFCVPrototype : NSCollectionViewItem

@property(nonatomic,assign) id<JFCVPrototypeDelegate> delegate;
@property(nonatomic,copy) NSString *scene;
@property(weak) IBOutlet NSButton *itemButton;


@end
