//
//  VMSTableView.h
//  VMS
//
//  Created by mac_dev on 16/8/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ExtendedTableViewDelegate <NSObject>

- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row;

@end

@interface VMSTableView : NSTableView

@property (nonatomic, assign) IBOutlet id<ExtendedTableViewDelegate> extendedDelegate;

@end
