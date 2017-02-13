//
//  JFPreferenceViewController.h
//  JFPreferencePanel
//
//  Created by mac_dev on 2016/10/22.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JFPreferenceViewController;

@protocol JFPreferenceViewControllerDelegate <NSObject>

- (void)preferencePanel:(JFPreferenceViewController *)src willForwardToPanel :(JFPreferenceViewController *)dest;
- (void)preferencePanel:(JFPreferenceViewController *)src willBackToPanel :(JFPreferenceViewController *)dest;

@end

@interface JFPreferenceViewController : NSViewController

@property (nonatomic,assign) id<JFPreferenceViewControllerDelegate> delegate;
@property (nonatomic,readonly,copy) NSString *panelTitle;
@property (nonatomic,weak) JFPreferenceViewController *backController;
@property (nonatomic,strong) JFPreferenceViewController *forwardController;

- (void)load;
- (void)goBack;

@end
