//
//  CMPConsentTool.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPConfig.h"
#import "CMPServerResponse.h"
#import "CMPSettings.h"
#import <UIKit/UIKit.h>

/**
 Object that needs to be initalised when starting the App
 */
@interface CMPConsentTool : NSObject

/**
 The singleton CMPConsentToolInstance
 */
extern CMPConsentTool *consentTool;

/**
 Returns the Config set to the CMPConsentTool while initialisation
 */
@property (nonatomic, retain) CMPConfig *cmpConfig;

/**
 The View Controler, the Web View schould shown onto.
 */
@property (nonatomic, weak) UIViewController *viewController;

/**
 This listener will be called, if the View of the consentTool will be closed
 */
@property (nonatomic, copy) void (^closeListener)(void);

/**
 This listener will be called, if the View of the consentTool will be opened
 */
@property (nonatomic, copy) void (^openListener)(void);

/**
 If this listener is set, this listener will be called, apart from openening an own View
 */
@property (nonatomic, copy) void (^customOpenListener)(CMPSettings *settings);

/**
 This listener will be called, if an error occurs while calling the Server or showing the view.
 */
@property (nonatomic, copy) void (^networkErrorListener)(NSString *error);

/**
 This listener will be called, if an error message will be returned from the consentmanager Server
 */
@property (nonatomic, copy) void (^serverErrorListener)(NSString *error);

/**
 Displays a modal view with the consent web view. If the Compliance is accepted or rejected,
 a close function will be called. You can overrride this close function with your own. Therefor
 implement the closeListener and add this as a parameter.
 */
- (void)openCmpConsentToolView;

/**
 Displays a modal view with the consent web view. If the Compliance is accepted or rejected,
 a close function will be called. You can overrride this close function with your own. Therefor
 implement the closeListener and give it to this function. This Method will not send a request
 to the ConsentTool Server again. It will use the last state. If you only want to open the consent
 Tool View again, if the server gives a response status ==1 use the checkAndProceedConsentUpdate
 method.
 */
- (void)openCmpConsentToolView: (void(^)(void))closeListener;

/**
 Returns the Vendors String, that was set by consentmanager
 */
- (NSString*)getVendorsString;

/**
 Returns the Purposes String, that was set by consentmanager
 */
- (NSString*)getPurposesString;

/**
 Returns the US Privacy String, that was set by consentmanager
 */
- (NSString*)getUSPrivacyString;

/**
 Returns if a given Vendor has the rights to set cookies
 */
- (BOOL)hasVendorConsent:(NSString *)vendorId vendorIsV1orV2:(BOOL)isIABVendor;

/**
 Returns if under a given Purpose the rights to set cookies are given
 */
- (BOOL)hasPurposeConsent:(NSString *)purposeId purposeIsV1orV2:(BOOL)isIABPurpose;

/**
 Returns, if the Consent for a purpose for a specific vendor was given. This Method will
 only give a valid answer, if the Consent was given in the version V2.
 */
- (BOOL)hasPurposeConsent:(int)purposeId forVendor:(int) vendorId;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController*)viewController;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addCloseListener:(void(^)(void))closeListener;
/**
Creates a new instance of this CMPConsentTool.
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController autoupdate:(BOOL)autoupdate addOpenListener:(void(^)(void))openListener addCloseListener:(void(^)(void))closeListener;
/**
  Returns the stored ConsentManager CMP String in base64
 */
+(NSString*)exportCMPData;

/**
  Imports the given CMPData String in base64
 */
+ (BOOL)importCMPData:(NSString *)cmpData;

/**
 * returns, wether the CMPConsent Manager Server was requested today, or the consentmanager server was already
 * asked, wether the server shuld be requested again.
 */
-(BOOL)calledThisDay;

/**
 * returns, weather the user needs to give a consent, cause he didn't do so in the past,
 * or because the consent Server returned, that a new consent is required.
 */
-(BOOL)needsAcceptance;


/**
 * resets all data set by the consentCMPTool
 */
+(void)reset;
@end
