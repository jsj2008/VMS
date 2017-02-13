//
//  NetViewController.m
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "NetViewController.h"
#import "XStringFomatter.h"
#import "../RegexKit/RegexKit/RegexKitLite.h"

@interface NetViewController ()

@end

@implementation NetViewController
@synthesize ipInfo = _ipInfo;
@synthesize portInfo = _portInfo;
#pragma mark - public api
- (void)fetch
{}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Network", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (NSString *)errMsg :(NSVC_ERR)code
{
    switch (code) {
        case NSVC_NO_ERR:
            return NSLocalizedString(@"success", nil);
            
        case NSVC_IP_FOMATE_ERR:
        case NSVC_MASK_FOMATE_ERR:
        case NSVC_GATE_FOMATE_ERR:
        case NSVC_DNS1_FOMATE_ERR:
        case NSVC_DNS2_FOMATE_ERR:
            return NSLocalizedString(@"ip format error", nil);
            
        case NSVC_INVALID_HTTP_PORT:
        case NSVC_INVALID_HTTPS_PORT:
        case NSVC_INVALID_ONVIF_PORT:
            return NSLocalizedString(@"invalid port", nil);
            
        case NSVC_SAME_PORT:
            return NSLocalizedString(@"same port", nil);
            
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

- (NSVC_ERR)parserIP
{
    NSString *regex = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    
    if (![self.ip.stringValue isMatchedByRegex:regex]) return NSVC_IP_FOMATE_ERR;
    if (![self.mask.stringValue isMatchedByRegex:regex]) return NSVC_MASK_FOMATE_ERR;
    if (![self.gate.stringValue isMatchedByRegex:regex]) return NSVC_GATE_FOMATE_ERR;
    if (![self.dns1.stringValue isMatchedByRegex:regex]) return NSVC_DNS1_FOMATE_ERR;
    if (![self.dns2.stringValue isMatchedByRegex:regex]) return NSVC_DNS2_FOMATE_ERR;
    
    return NSVC_NO_ERR;
}

- (NSVC_ERR)parserPort
{
    NSInteger webPort = self.webPort? self.webPort.integerValue : VMS_INVALIDP_PORT;
    NSInteger httpsPort = self.httpsPort? self.httpsPort.integerValue : VMS_INVALIDP_PORT;
    NSInteger onvifPort = self.onvifPort? self.onvifPort.integerValue : VMS_INVALIDP_PORT;
    
    
    if ((VMS_INVALIDP_PORT != webPort) && (webPort <VMS_MIN_PORT || webPort > VMS_MAX_PORT))
        return NSVC_INVALID_HTTP_PORT;
    if ((VMS_INVALIDP_PORT != httpsPort) && (httpsPort <VMS_MIN_PORT || httpsPort > VMS_MAX_PORT))
        return NSVC_INVALID_HTTPS_PORT;
    if ((VMS_INVALIDP_PORT != onvifPort) && (onvifPort <VMS_MIN_PORT || onvifPort > VMS_MAX_PORT))
        return NSVC_INVALID_ONVIF_PORT;
    if (((VMS_INVALIDP_PORT != webPort) && (webPort == httpsPort)) ||
        ((VMS_INVALIDP_PORT != onvifPort) && (webPort == onvifPort)) ||
        ((VMS_INVALIDP_PORT != httpsPort) && (httpsPort == onvifPort)))
        return NSVC_SAME_PORT;
    
    
    return NSVC_NO_ERR;
}

#pragma mark setter && getter
- (void)setIpInfo:(FOS_IPINFO)ipInfo
{
    _ipInfo = ipInfo;
    self.isDHCP = ipInfo.isDHCP;
    
    [self.ip setStringValue:[NSString stringWithCString:ipInfo.ip encoding:NSASCIIStringEncoding]];
    [self.mask setStringValue:[NSString stringWithCString:ipInfo.mask encoding:NSASCIIStringEncoding]];
    [self.gate setStringValue:[NSString stringWithCString:ipInfo.gate encoding:NSASCIIStringEncoding]];
    [self.dns1 setStringValue:[NSString stringWithCString:ipInfo.dns1 encoding:NSASCIIStringEncoding]];
    [self.dns2 setStringValue:[NSString stringWithCString:ipInfo.dns2 encoding:NSASCIIStringEncoding]];
}

- (FOS_IPINFO)ipInfo
{
    _ipInfo.isDHCP = self.isDHCP;
    
    [self.ip.stringValue getCString:_ipInfo.ip maxLength:IPADDR_LEN encoding:NSASCIIStringEncoding];
    [self.mask.stringValue getCString:_ipInfo.mask maxLength:MASK_LEN encoding:NSASCIIStringEncoding];
    [self.gate.stringValue getCString:_ipInfo.gate maxLength:GATE_LEN encoding:NSASCIIStringEncoding];
    [self.dns1.stringValue getCString:_ipInfo.dns1 maxLength:DNS_LEN encoding:NSASCIIStringEncoding];
    [self.dns2.stringValue getCString:_ipInfo.dns2 maxLength:DNS_LEN encoding:NSASCIIStringEncoding];
   
    return _ipInfo;
}

- (void)setPortInfo:(FOS_PORTINFO)portInfo
{
    _portInfo = portInfo;
    [self.webPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.webPort]];
    [self.httpsPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.httpsPort]];
    [self.onvifPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.onvifPort]];
}

- (FOS_PORTINFO)portInfo
{
    _portInfo.httpsPort = [self.httpsPort intValue];
    _portInfo.webPort = [self.webPort intValue];
    _portInfo.onvifPort = [self.onvifPort intValue];
    return _portInfo;
}


@end
