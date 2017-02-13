//
//  JFPreferenceRootViewController.h
//  JFPreferencePanel
//
//  Created by mac_dev on 2016/10/22.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferenceViewController.h"
#import "JFCVPrototype.h"

@interface JFPreferenceRootViewController : JFPreferenceViewController<NSCollectionViewDelegate,
JFCVPrototypeDelegate>

@property(nonatomic,strong) NSArray *items;
@end
