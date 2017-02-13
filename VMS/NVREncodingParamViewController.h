//
//  NVREncodingParamViewController.h
//  
//
//  Created by mac_dev on 16/5/28.
//
//

#import "EncodingParamViewController.h"

@interface NVREncodingParamViewController : EncodingParamViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (FOS_NVR_VIDEOSTREAMPARAM)nvrStreamEncoderArgs;
- (FOS_NVR_VIDEOSTREAMPARAM)nvrSubStreamEncoderArgs;
@end
