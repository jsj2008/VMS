//
//  OSDMaskViewController.h
//  
//
//  Created by mac_dev on 16/6/2.
//
//

#import "OSDViewController.h"

@interface OSDMaskViewController : OSDViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (BOOL)enableOSD;
- (BOOL)enablePrivacyCover;
@end
