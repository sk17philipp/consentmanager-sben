//
//  CMPConsentTool.m
//  GDPA
//
//

#import <Foundation/Foundation.h>
#import "CMPConsentTool.h"
#import "CMPDataStorageConsentManagerUserDefaults.h"
#import "CMPDataStorageV1UserDefaults.h"
#import "CMPDataStorageV2UserDefaults.h"
#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPTypes.h"
#import "CMPConsentToolViewController.h"
#import "CMPConsentToolUtil.h"
#import "CMPConsentV1Parser.h"
#import "CMPConsentV2Parser.h"

@interface CMPConsentTool() <CMPConsentToolViewControllerDelegate>
@end

@implementation CMPConsentTool

@synthesize closeListener;
@synthesize openListener;
@synthesize networkErrorListener;
@synthesize serverErrorListener;
@synthesize customOpenListener;

- (CMPConfig *)cmpConfig {
    return _cmpConfig;
}

- (void)closeListener:(void(^)(void))listener {
    closeListener = listener;
}

- (void)openListener:(void(^)(void))listener {
    openListener = listener;
}

- (void)customOpenListener:(void(^)(CMPSettings *settings))listener {
    customOpenListener = listener;
}

- (void)networkErrorListener:(void(^)(NSString *error))listener {
    networkErrorListener = listener;
}

- (void)serverErrorListener:(void(^)(NSString *error))listener {
    serverErrorListener = listener;
}

- (void)openCmpConsentToolView{
    [self openCmpConsentToolView:self.closeListener];
}

- (void)openCmpConsentToolView:(void(^)(void)) closeListener{
    if( self.openListener){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self.openListener();
        });
    }
    [CMPDataStorageV1UserDefaults setCmpPresent:TRUE];

    if(self.customOpenListener){
        if( ![CMPSettings consentToolUrl] || [[CMPSettings consentToolUrl] isEqualToString:@""]){
            NSLog(@"ConsentToolUrl is not known. Reasking the Server");
            CMPServerResponse *cmpServerResponse = [self proceedServerRequest];
            [self proceedConsentUpdate:cmpServerResponse withOpening:FALSE];
            [CMPSettings setConsentString:[CMPDataStorageConsentManagerUserDefaults consentString]];
        }
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self.customOpenListener([CMPSettings self]);
        });
        
        return;
    }
    if( [CMPConfig isValid]){
        [CMPSettings setConsentString:[CMPDataStorageConsentManagerUserDefaults consentString]];
        CMPConsentToolViewController *consentToolVC = [[CMPConsentToolViewController alloc] init];
        consentToolVC.delegate = self;
        [self.viewController presentViewController:consentToolVC animated:YES completion:nil];
    } else {
        NSLog(@"CMPConfig is invalid");
    }
}

#pragma mark CMPConsentToolViewController delegate
-(void)consentToolViewController:(CMPConsentToolViewController *)consentToolViewController didReceiveConsentString:(NSString *)consentString {
    
    [consentToolViewController dismissViewControllerAnimated:YES completion:nil];
    [CMPConsentTool parseConsentManagerString: consentString];
    if(self.closeListener){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self.closeListener();
        });
        
    }
}

+ (void) parseConsentManagerString:(NSString *)consentString{
    [CMPDataStorageV1UserDefaults setCmpPresent:FALSE];
    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [CMPDataStoragePrivateUserDefaults setNeedsAcceptance:FALSE];
    
    @try {
       if( consentString != NULL && consentString != nil && consentString.length > 0 && ![consentString isEqualToString:@"null"] && ![consentString isEqualToString:@"nil"] && ![consentString isEqualToString:@""]){
           [CMPDataStorageConsentManagerUserDefaults setConsentString:consentString];
           NSString *base64Decoded = [CMPConsentToolUtil binaryStringConsentFrom:consentString];

           NSArray *splits = [base64Decoded componentsSeparatedByString:@"#"];

           if( splits.count > 3){
               NSLog(@"ConsentManager String detected");
               [[CMPConsentTool self] proceedConsentString:[splits objectAtIndex:0]];
               [self proceedConsentManagerValues:splits];
           } else {
               [CMPDataStorageV1UserDefaults clearContents];
               [CMPDataStorageV2UserDefaults clearContents];
               [CMPDataStorageConsentManagerUserDefaults clearContents];
           }
       } else {
           [CMPDataStorageV1UserDefaults clearContents];
           [CMPDataStorageV2UserDefaults clearContents];
           [CMPDataStorageConsentManagerUserDefaults clearContents];
       }
    }
    @catch (NSException * e) {
       [CMPDataStorageV1UserDefaults clearContents];
       [CMPDataStorageV2UserDefaults clearContents];
       [CMPDataStorageConsentManagerUserDefaults clearContents];
    }
    
}

+(BOOL)importCMPData:(NSString*)cmpData{
    [CMPConsentTool parseConsentManagerString:cmpData];
    return TRUE;
}

+(NSString*)exportCMPData{
    return [CMPDataStorageConsentManagerUserDefaults consentString];
}

+(void)proceedConsentString:(NSString*)consentS{
    
    if( [[consentS substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"B"] ){
        NSLog(@"V1 String detected");
        [CMPDataStorageV2UserDefaults clearContents];
        [CMPDataStorageV1UserDefaults setConsentString:consentS];
        [CMPDataStorageV1UserDefaults setParsedVendorConsents:[CMPConsentV1Parser parseVendorConsentsFrom:consentS ]];
        [CMPDataStorageV1UserDefaults setParsedPurposeConsents:[CMPConsentV1Parser parsePurposeConsentsFrom:consentS ]];
    } else {
        NSLog(@"V2 String detected");
        [CMPDataStorageV1UserDefaults clearContents];
        [CMPDataStorageV2UserDefaults setTcString:consentS];
        [[CMPConsentV2Parser alloc] init:consentS];
    }
}

+(void)proceedConsentManagerValues:(NSArray*)splits{
    if( splits.count > 1){
        [CMPDataStorageConsentManagerUserDefaults setParsedPurposeConsents:[splits objectAtIndex:1]];
        NSLog(@"ParsedPurposeConsents:%@", [splits objectAtIndex:1]);
    }
    if( splits.count > 2){
        [CMPDataStorageConsentManagerUserDefaults setParsedVendorConsents:[splits objectAtIndex:2]];
        NSLog(@"ParsedVendorConsents:%@", [splits objectAtIndex:2]);
    }
    if( splits.count > 3){
        [CMPDataStorageConsentManagerUserDefaults setUsPrivacyString:[splits objectAtIndex:3]];
        NSLog(@"ParsedUSPrivacy:%@", [splits objectAtIndex:3]);
    }
    if( splits.count > 4){
        [CMPDataStorageConsentManagerUserDefaults setGoogleACString:[splits objectAtIndex:4]];
        NSLog(@"GoogleACString:%@", [splits objectAtIndex:4]);
    }
}


- (NSString*)getVendorsString{
    return [CMPDataStorageConsentManagerUserDefaults parsedVendorConsents];
}

- (NSString*)getPurposesString{
    return [CMPDataStorageConsentManagerUserDefaults parsedPurposeConsents];
}

- (NSString*)getUSPrivacyString{
    return [CMPDataStorageConsentManagerUserDefaults usPrivacyString];
}

- (NSString*)getGoogleACString{
    return [CMPDataStorageConsentManagerUserDefaults googleACString];
}


- (BOOL)hasVendorConsent:(NSString *)vendorId vendorIsV1orV2:(BOOL)isIABVendor{
    @try
    {
        if( isIABVendor ){
            int vendorIdInt = [vendorId intValue];
            NSString *x = [CMPDataStorageV1UserDefaults parsedVendorConsents];
            if([x length] > 0 && ([x length] > vendorIdInt && vendorIdInt > 0)){
                if( [[x substringWithRange:NSMakeRange(vendorIdInt - 1, 1)] isEqualToString:@"1"]){
                    return TRUE;
                }
            }
            
            x = [CMPDataStorageV2UserDefaults vendorConsents];
            if([x length] > vendorIdInt && vendorIdInt > 0){
                if( [[x substringWithRange:NSMakeRange(vendorIdInt - 1, 1)] isEqualToString:@"1"]){
                    return TRUE;
                }
            }
            return FALSE;
        } else {
            NSString *x = [CMPDataStorageConsentManagerUserDefaults parsedVendorConsents];
            return [x containsString: [NSString stringWithFormat:@"_%@_", vendorId]];
        }
    }
    @catch(id anException) {
        return FALSE;
    }
}

- (BOOL)hasPurposeConsent:(NSString *)purposeId purposeIsV1orV2:(BOOL)isIABPurpose{
    @try
    {
        if( isIABPurpose ){
            int purposeIdInt = [purposeId intValue];
            NSString *x = [CMPDataStorageV1UserDefaults parsedPurposeConsents];
            if([x length] > 0 && ([x length] > purposeIdInt && purposeIdInt > 0)){
                if( [[x substringWithRange:NSMakeRange(purposeIdInt - 1, 1)] isEqualToString:@"1"]){
                    return TRUE;
                }
            }

            x = [CMPDataStorageV2UserDefaults purposeConsents];
            if([x length] > purposeIdInt && purposeIdInt > 0){
                if( [[x substringWithRange:NSMakeRange(purposeIdInt - 1, 1)] isEqualToString:@"1"]){
                    return TRUE;
                }
            }

            return FALSE;
        } else {
            NSString *x = [CMPDataStorageConsentManagerUserDefaults parsedPurposeConsents];
            return [x containsString: [NSString stringWithFormat:@"_%@_", purposeId]];
        }
    }
    @catch(id anException) {
        return FALSE;
    }
}

- (BOOL)hasPurposeConsent:(int)purposeId forVendor:(int)vendorId {
    @try
    {
        NSNumber *purposeIdInt = [NSNumber numberWithInt:purposeId];

        PublisherRestriction *pr = [CMPDataStorageV2UserDefaults publisherRestriction:purposeIdInt];
        return [pr hasVendor:vendorId];
    }
    @catch(id anException) {
        return FALSE;
    }
}



- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController{
    return [self init:domain addId:userId addAppName:appName addLanguage:language addViewController:viewController autoupdate: TRUE];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener{
    return [self init:domain addId:userId addAppName:appName addLanguage:language addViewController:viewController autoupdate: TRUE addOpenListener:openListener];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addCloseListener:(void(^)(void))closeListener{
    return [self init:domain addId:userId addAppName:appName addLanguage:language addViewController:viewController autoupdate: TRUE addCloseListener:closeListener];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener{
    return [self init:domain addId:userId addAppName:appName addLanguage:language addViewController:viewController autoupdate: TRUE addOpenListener:openListener addCloseListener:closeListener];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate{
    [CMPConfig setValues:domain addId:userId addAppName:appName addLanguage:language];
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:autoupdate];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener {
    [CMPConfig setValues:domain addId:userId addAppName:appName addLanguage:language];
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:autoupdate addOpenListener:openListener];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addCloseListener:(void(^)(void))closeListener{
    [CMPConfig setValues:domain addId:userId addAppName:appName addLanguage:language];
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:autoupdate addCloseListener:closeListener];
}

- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener{
    [CMPConfig setValues:domain addId:userId addAppName:appName addLanguage:language];
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:autoupdate addOpenListener:openListener addCloseListener:closeListener];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController{
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:TRUE];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener{
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:TRUE addOpenListener:openListener];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addCloseListener:(void(^)(void))closeListener{
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:TRUE addCloseListener:closeListener];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener{
    return [self init:[CMPConfig self] withViewController:viewController autoupdate:TRUE addOpenListener:openListener addCloseListener:closeListener];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate{
    return [self init:config withViewController:viewController autoupdate:autoupdate addOpenListener:nil addCloseListener:nil];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener{
    return [self init:config withViewController:viewController autoupdate:autoupdate addOpenListener:openListener addCloseListener:nil];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addCloseListener:(void(^)(void))closeListener{
    return [self init:config withViewController:viewController autoupdate:autoupdate addOpenListener:nil addCloseListener:closeListener];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener{
    self.cmpConfig = config;
    self.viewController = viewController;
    self.closeListener = closeListener;
    self.openListener = openListener;
    
    [self checkAndProceedConsentUpdate];
    
    if( autoupdate ){
        [[NSNotificationCenter defaultCenter] addObserver:self.viewController
                                                 selector:@selector(onApplicationDidBecomeActive:)
        name:@"NSApplicationDidBecomeActiveNotification"
        object:nil];
    }

    return self;
}

-(void)onApplicationDidBecomeActive:(NSNotification*)notification{
    [self checkAndProceedConsentUpdate];
}

-(void)checkAndProceedConsentUpdate{
    if([self needsServerUpdate]){
        CMPServerResponse *cmpServerResponse = [self proceedServerRequest];
        if( cmpServerResponse && cmpServerResponse != nil ){
            [self proceedConsentUpdate:cmpServerResponse];
        }
    } else if([self needsConsentAcceptance]){
        [self openCmpConsentToolView];
    } else {
        NSLog(@"No update needed. Server was already requested today and Consent was given.");
    }
}

-(void)showErrorMessage:(NSString *)message{
    if( serverErrorListener){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self.serverErrorListener(message);
        });
        
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.viewController presentViewController:alert animated:YES completion:nil];
    }
}

-(BOOL) needsServerUpdate{
    return ! [self calledThisDay];
}

-(BOOL) needsConsentAcceptance{
    return [self needsAcceptance];
}

-(CMPServerResponse*)proceedServerRequest{
    return [CMPConsentToolUtil getAndSaveServerResponse:networkErrorListener
                                    serverErrorListener: serverErrorListener
        withConsent:[CMPDataStorageConsentManagerUserDefaults consentString]];
}

-(void)proceedConsentUpdate:(CMPServerResponse *)cmpServerResponse{
    [self proceedConsentUpdate:cmpServerResponse withOpening:TRUE];
}

-(void)proceedConsentUpdate:(CMPServerResponse *)cmpServerResponse withOpening:(BOOL)opening{
    if( cmpServerResponse == nil || !cmpServerResponse || !cmpServerResponse.url || [cmpServerResponse.url isEqualToString:@""]){
        NSLog(@"The Response is not valid.");
        return;
    }
    switch ([cmpServerResponse.status intValue]) {
        case 0:
            return;
        case 1:
            if(opening){
                [CMPDataStoragePrivateUserDefaults setNeedsAcceptance:TRUE];
                [self openCmpConsentToolView];
            }
            return;
        default:
            [self showErrorMessage:cmpServerResponse.message];
            break;
    }
}

-(BOOL)calledThisDay{
    NSString *last = [self getCalledLast];
    if( last ){
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return [now isEqualToString: last];
    }
    return FALSE;
}

-(BOOL)needsAcceptance{
    return [CMPDataStoragePrivateUserDefaults needsAcceptance];
}

-(NSString*)getCalledLast{
    return [CMPDataStoragePrivateUserDefaults lastRequested];
}

+(void)reset{
    [CMPDataStorageV1UserDefaults clearContents];
    [CMPDataStorageV2UserDefaults clearContents];
    [CMPDataStoragePrivateUserDefaults clearContents];
    [CMPDataStorageConsentManagerUserDefaults clearContents];
}

@end
