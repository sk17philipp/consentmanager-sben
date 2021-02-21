//
//  CMPDataStorageV1UserDefaults.m
//  GDPR
//

#import "CMPDataStorageV1UserDefaults.h"

NSString *const IABConsent_SubjectToGDPRKey = @"IABConsent_SubjectToGDPR";
NSString *const IABConsent_ConsentStringKey = @"IABConsent_ConsentString";
NSString *const IABConsent_ParsedVendorConsentsKey = @"IABConsent_ParsedVendorConsents";
NSString *const IABConsent_ParsedPurposeConsentsKey = @"IABConsent_ParsedPurposeConsents";
NSString *const IABConsent_CMPPresentKey = @"IABConsent_CMPPresent";

@implementation CMPDataStorageV1UserDefaults

static NSUserDefaults *userDefaults = nil;

+(NSString *)consentString {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    return [userDefaults stringForKey:IABConsent_ConsentStringKey];
}

+(void)setConsentString:(NSString *)consentString{
    NSUserDefaults *userDefaults = [self getUserDefaults];
    [userDefaults setObject:consentString forKey:IABConsent_ConsentStringKey];
    [userDefaults synchronize];
}

+(SubjectToGDPR)subjectToGDPR {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    NSString *subjectToGDPRAsString = [userDefaults stringForKey:IABConsent_SubjectToGDPRKey];

    if (subjectToGDPRAsString != nil) {
        if ([subjectToGDPRAsString isEqualToString:@"0"]) {
            return SubjectToGDPR_No;
        } else if ([subjectToGDPRAsString isEqualToString:@"1"]) {
            return SubjectToGDPR_Yes;
        } else {
            return SubjectToGDPR_Unknown;
        }
    } else {
        return SubjectToGDPR_Unknown;
    }
}

+(void)setSubjectToGDPR:(SubjectToGDPR)subjectToGDPR {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    NSString *subjectToGDPRAsString = nil;

    if (subjectToGDPR == SubjectToGDPR_No || subjectToGDPR == SubjectToGDPR_Yes) {
        subjectToGDPRAsString = [NSString stringWithFormat:@"%li", (long)subjectToGDPR];
    }

    [userDefaults setObject:subjectToGDPRAsString forKey:IABConsent_SubjectToGDPRKey];
    [userDefaults synchronize];
}

+(BOOL)cmpPresent {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    return [userDefaults boolForKey:IABConsent_CMPPresentKey];
}

+(void)setCmpPresent:(BOOL)cmpPresent {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    [userDefaults setBool:cmpPresent forKey:IABConsent_CMPPresentKey];
    [userDefaults synchronize];
}

+(NSString *)parsedVendorConsents {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    return [userDefaults stringForKey:IABConsent_ParsedVendorConsentsKey];
}

+(void)setParsedVendorConsents:(NSString *)parsedVendorConsents {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    [userDefaults setObject:parsedVendorConsents forKey:IABConsent_ParsedVendorConsentsKey];
    [userDefaults synchronize];
}

+(NSString *)parsedPurposeConsents {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    return [userDefaults stringForKey:IABConsent_ParsedPurposeConsentsKey];
}

+(void)setParsedPurposeConsents:(NSString *)parsedPurposeConsents {
    NSUserDefaults *userDefaults = [self getUserDefaults];
    [userDefaults setObject:parsedPurposeConsents forKey:IABConsent_ParsedPurposeConsentsKey];
    [userDefaults synchronize];
}

+(NSUserDefaults*)getUserDefaults{
    if( userDefaults == nil){
        userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return userDefaults;
    
}

+(void)clearContents{
    NSLog(@"cleaning the userDefaults V1");
    [self setParsedPurposeConsents:@""];
    [self setParsedVendorConsents:@""];
    [self setCmpPresent:FALSE];
    [self setSubjectToGDPR:SubjectToGDPR_Unknown];
    [self setConsentString:@""];
}

@end
