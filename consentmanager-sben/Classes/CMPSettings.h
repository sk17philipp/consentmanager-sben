//
//  CMPConfig.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPTypes.h"

/**
 Object that provides the interface for storing and retrieving GDPR-related information
 */
@interface CMPSettings : NSObject


/**
* Setter for the consentString which was returned from the Server
*/
+ (void)setConsentString:(NSString *)consentString;

/**
* Returns the consentString which was returned from the Server and saved in
* this instance
*/
+(NSString *)consentString;

/**
* Setter for the setSubjectToGdpr which was returned from the Server
*/
+ (void)setSubjectToGdpr:(SubjectToGDPR)subjectToGdpr;

/**
* Returns the subjectToGdpr which was returned from the Server and saved in
* this instance
*/
+(SubjectToGDPR)subjectToGdpr;

/**
* Setter for the consentToolUrl which was returned from the Server
*/
+ (void)setConsentToolUrl:(NSString *)consentToolUrl;

/**
* Returns the consentToolUrl which was returned from the Server and saved in 
* this instance
*/
+(NSString *)consentToolUrl;

/**
 Creates a new singleton Instance from the Settings and Returns this
 */
+ (void)setValues:(SubjectToGDPR)subjectToGdpr addConsentToolUrl:(NSString *)consentToolUrl addConsentString:(NSString *)consentString;


@end
