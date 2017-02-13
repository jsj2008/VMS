//
//  AmbaDetectComponentViewController.h
//  
//
//  Created by mac_dev on 16/4/5.
//
//

#import <Cocoa/Cocoa.h>

@interface AmbaDetectComponentViewController : NSViewController

@property(nonatomic,assign) int valid;
@property(nonatomic,assign) int sensitivity;
@property(nonatomic,assign,readonly) NSInteger index;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                          index:(NSUInteger)index;
- (int)sensitivityFromUI;

@end
