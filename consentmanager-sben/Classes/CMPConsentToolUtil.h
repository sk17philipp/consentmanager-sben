//
//  CMPConsentToolUtil.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "CMPServerResponse.h"
#import "CMPConfig.h"

@interface CMPConsentToolUtil : NSObject

+(NSString*)addPaddingIfNeeded:(NSString*)base64String;
+(unsigned char*)NSDataToBinary:(NSData *)decodedData;
+(NSString*)replaceSafeCharacters:(NSString*)consentString;
+(NSString*)safeBase64ConsentString:(NSString*)consentString;
+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex toIndex:(int)endIndex;
+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset;
+(NSString*)BinaryToString:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset;
+(NSString*)BinaryToLanguage:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset;
+(NSNumber*)BinaryToNumber:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset;
+(BOOL)isNetworkAvailable;
+(CMPServerResponse*)getAndSaveServerResponse: (void(^)(NSString *error))networkErrorListener serverErrorListener:(void(^)(NSString *error))serverErrorListener withConsent:(NSString *)consent;
+(unsigned char*)binaryConsentFrom:(NSString *)consentString;

+(NSString *)binaryStringConsentFrom:(NSString *)consentString;

@end
