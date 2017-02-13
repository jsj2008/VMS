//
//  NVROSDViewController.h
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "OSDViewController.h"

@interface NVROSDViewController : OSDViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (BOOL)enableOSD;
- (BOOL)enablePrivacyCover;

@end
