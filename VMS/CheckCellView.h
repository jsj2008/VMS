//
//  CheckCellView.h
//  
//
//  Created by mac_dev on 16/6/14.
//
//

#import <Cocoa/Cocoa.h>

@interface CheckCellView : NSTableCellView

@property(nonatomic,assign) BOOL hidden;
@property(nonatomic,assign) BOOL state;
@property(nonatomic,assign) NSInteger tag;

@end
