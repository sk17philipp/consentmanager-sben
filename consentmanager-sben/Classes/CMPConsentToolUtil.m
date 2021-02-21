//
//  CMPConsentToolUtil.m
//  GDPR
//

#import "CMPConsentToolUtil.h"
#import "Reachability.h"
#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPSettings.h"
#include <math.h>

NSString *const RESPONSE_MESSAGE_KEY = @"message";
NSString *const RESPONSE_STATUS_KEY = @"status";
NSString *const RESPONSE_REGULATION_KEY = @"regulation";
NSString *const RESPONSE_URL_KEY = @"url";

@implementation CMPConsentToolUtil

+(unsigned char*)NSDataToBinary:(NSData *)decodedData {
    const char *byte = [decodedData bytes];
    NSUInteger length = [decodedData length];
    unsigned long bufferLength = decodedData.length*8 - 1;
    unsigned char *buffer = (unsigned char *)calloc(bufferLength, sizeof(unsigned char));
    int prevIndex = 0;
    
    for (int byteIndex=0; byteIndex<length; byteIndex++) {
        char currentByte = byte[byteIndex];
        int bufferIndex = 8*(byteIndex+1);
        
        while(bufferIndex > prevIndex) {
            if(currentByte & 0x01) {
                buffer[--bufferIndex] = '1';
            } else {
                buffer[--bufferIndex] = '0';
            }
            currentByte >>= 1;
        }
        
        prevIndex = 8*(byteIndex+1);
    }
    
    return buffer;
}

+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex toIndex:(int)endIndex {
    return [self BinaryToDecimal:buffer fromIndex:startIndex length:(endIndex - startIndex)];
}

+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    size_t length =  (int)strlen((const char *)buffer);
    
    if (length <= startIndex || length <= startIndex + totalOffset - 1) {
        return 0;
    }
    
    NSInteger total = 0;
    int from = (startIndex + totalOffset - 1);
    for (int i=from; i >=startIndex; i--) {
        if (buffer[i] == '1') {
            
            total += pow(2, abs(from - i));
        }
    }
    
    return total;
}

+(NSString*)BinaryToString:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    size_t length =  (int)strlen((const char *)buffer);

    if (length <= startIndex || length < startIndex + totalOffset) {
        return 0;
    }
    
    NSMutableString *total = [NSMutableString new];
    
    for (int i=startIndex; i < (startIndex + totalOffset); i++) {
        [total appendString:[NSString stringWithFormat:@"%c",buffer[i]]];
    }
    
    return total;
}

+(NSNumber*)BinaryToNumber:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    return [NSNumber numberWithInteger:[CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:startIndex length:totalOffset]];
}



+(NSString*)BinaryToLanguage:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    size_t length =  (int)strlen((const char *)buffer);
    
    if (length <= startIndex || length <= startIndex + totalOffset - 1) {
        return 0;
    }
    
    NSMutableString *language = [NSMutableString new];
    
    NSString* first = [self getLetter:[CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:startIndex length:totalOffset - 6]];
    [language appendString:first];
    
    NSString* second = [self getLetter:[CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:startIndex + 6 length:totalOffset - 6]];
    [language appendString:second];
    
    return language;
}

+(NSString*)getLetter:(NSInteger)letterNumber {
    switch (letterNumber) {
        case 0: return @"A"; break;
        case 1: return @"B"; break;
            case 2: return @"C"; break;
            case 3: return @"D"; break;
            case 4: return @"E"; break;
            case 5: return @"F"; break;
            case 6: return @"G"; break;
            case 7: return @"H"; break;
            case 8: return @"I"; break;
            case 9: return @"J"; break;
            case 10: return @"K"; break;
            case 11: return @"L"; break;
            case 12: return @"M"; break;
            case 13: return @"N"; break;
            case 14: return @"O"; break;
            case 15: return @"P"; break;
            case 16: return @"Q"; break;
            case 17: return @"R"; break;
            case 18: return @"S"; break;
            case 19: return @"T"; break;
            case 20: return @"U"; break;
            case 21: return @"V"; break;
            case 22: return @"W"; break;
            case 23: return @"X"; break;
            case 24: return @"Y"; break;
            case 25: return @"Z"; break;
    }
    return @"";
}



+(NSString*)addPaddingIfNeeded:(NSString*)base64String {
    int padLenght = (4 - (base64String.length % 4)) % 4;
    NSString *paddedBase64 = [NSString stringWithFormat:@"%s%.*s", [base64String UTF8String], padLenght, "=="];
    return paddedBase64;
}

+(NSString*)replaceSafeCharacters:(NSString*)consentString {
    NSString *stringreplace = [consentString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    stringreplace = [stringreplace stringByReplacingOccurrencesOfString:@"%2B" withString:@"+"];
    stringreplace = [stringreplace stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    stringreplace = [stringreplace stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *finalString = [stringreplace stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    return finalString;
}

+(NSString*)safeBase64ConsentString:(NSString*)consentString {
    NSString *safeString = [CMPConsentToolUtil replaceSafeCharacters:consentString];
    NSString *base64String = [CMPConsentToolUtil addPaddingIfNeeded:safeString];
    return base64String;
}

+(BOOL)isNetworkAvailable{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return FALSE;
    } else {
        return TRUE;
    }
}

+(CMPServerResponse*)getAndSaveServerResponse: (void(^)(NSString *error))networkErrorListener serverErrorListener:(void(^)(NSString *error))serverErrorListener withConsent:(NSString *)consent{
    if( [self isNetworkAvailable]){
        NSDictionary *responseDictionary = [self requestSynchronousJSONWithURLString:[CMPConfig getConsentToolURLString:consent]];
        if( responseDictionary && responseDictionary != nil){
            @try{
                CMPServerResponse *response = [[CMPServerResponse alloc] init];
                response.message = [responseDictionary objectForKey:RESPONSE_MESSAGE_KEY];
                response.status = [NSNumber numberWithInt:[[responseDictionary objectForKey:RESPONSE_STATUS_KEY] intValue]];
                response.regulation = [NSNumber numberWithInt:[[responseDictionary objectForKey:RESPONSE_REGULATION_KEY] intValue]];
                response.url = [responseDictionary objectForKey:RESPONSE_URL_KEY];
                NSLog(@"message: %@ status: %@ regulation: %@ url: %@", response.message, response.status, response.regulation, response.url);
                
                [CMPSettings setConsentToolUrl:response.url];
                
                if( [response.regulation isEqual: @1]){
                    [CMPSettings setSubjectToGdpr:SubjectToGDPR_Yes];
                } else {
                    [CMPSettings setSubjectToGdpr:SubjectToGDPR_No];
                }
                
                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                [CMPDataStoragePrivateUserDefaults setLastRequested:[dateFormatter stringFromDate:[NSDate date]]];
                return response;
            } @catch(id anException) {
                NSLog(@"ConsentManager Server response was incorrect");
                if(serverErrorListener){
                        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                        dispatch_async(queue, ^{
                            serverErrorListener(@"ConsentManager Server response was incorrect. Maybe a wrong url was given.");
                        });
                    
                }
                return nil;
            }
        } else {
            NSLog(@"ConsentManager Server coudn't be contacted");
            if(serverErrorListener){
                    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(queue, ^{
                        serverErrorListener(@"The Server coudn't be contacted, because no Network Connection was found, or the server is down.");
                    });
                
            }
            return nil;
        }
    
    } else {
        NSLog(@"Network was not available");
        
        if(networkErrorListener){
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                networkErrorListener(@"The Server coudn't be contacted, because no Network Connection was found");
            });
        }
        return nil;
    }}


+ (NSData *)requestSynchronousData:(NSURLRequest *)request
{
    __block NSData *data = [[NSData alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *response, NSError *error) {
        data = taskData;
        if (!data) {
            NSLog(@"%@", error);
        }
        dispatch_semaphore_signal(semaphore);
        
    }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return data;
}

+ (NSData *)requestSynchronousDataWithURLString:(NSString *)requestString
{
    NSURL *url = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return [self requestSynchronousData:request];
}

+ (NSDictionary *)requestSynchronousJSON:(NSURLRequest *)request
{
    NSData *data = [self requestSynchronousData:request];
    NSError *e = nil;
    if( data != nil && data != NULL && data.length > 0){
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        return jsonData;
    } else {
        return nil;
    }
}

+ (NSDictionary *)requestSynchronousJSONWithURLString:(NSString *)requestString
{
    @try {
        NSURL *url = [NSURL URLWithString:requestString];
        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:5];
        theRequest.HTTPMethod = @"GET";
        [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        return [self requestSynchronousJSON:theRequest];
    } @catch (NSException *exception) {
        return nil;
    }
    
}

+(unsigned char*)binaryConsentFrom:(NSString *)consentString {
    NSString* safeString = [CMPConsentToolUtil safeBase64ConsentString:consentString];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:safeString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    if (!decodedData) {
        return nil;
    }
    
    return [CMPConsentToolUtil NSDataToBinary:decodedData];
}

+(NSString *)binaryStringConsentFrom:(NSString *)consentString {
    NSString* safeString = [CMPConsentToolUtil safeBase64ConsentString:consentString];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:safeString options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}




@end
