//
//  CMPConfig.m
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPSettings.h"
#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPDataStorageV1UserDefaults.h"
#import "CMPDataStorageV2UserDefaults.h"

@implementation CMPSettings

+(void)setValues:(SubjectToGDPR)stg addConsentToolUrl:(NSString *)ctu addConsentString:(NSString *)cs {
    [self setConsentString:cs];
    [self setConsentToolUrl:ctu];
    [self setSubjectToGdpr:stg];
}

+ (void)setConsentString:(NSString *)cs {
    [CMPDataStorageV1UserDefaults setConsentString:cs];
}

+(NSString *)consentString {
    return [CMPDataStorageV1UserDefaults consentString];
}

+ (void)setSubjectToGdpr:(SubjectToGDPR)stg{
    [CMPDataStorageV1UserDefaults setSubjectToGDPR:stg];
    if (stg == SubjectToGDPR_Yes) {
        [CMPDataStorageV2UserDefaults setGdprApplies:@1];
    } else {
        [CMPDataStorageV2UserDefaults setGdprApplies:@0];
    }
    
}

+(SubjectToGDPR)subjectToGdpr {
    return [CMPDataStorageV1UserDefaults subjectToGDPR];
}

+ (void)setConsentToolUrl:(NSString *)ctu{
    [CMPDataStoragePrivateUserDefaults setConsentToolUrl:ctu];
}

+(NSString *)consentToolUrl {
    return [CMPDataStoragePrivateUserDefaults consentToolUrl];
}

@end
