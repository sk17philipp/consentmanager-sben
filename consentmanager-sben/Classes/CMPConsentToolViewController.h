//
//  CMPConsentToolViewController.h
//  GDPR
//

#import <UIKit/UIKit.h>

@class CMPConsentToolViewController;
@protocol CMPConsentToolViewControllerDelegate <NSObject>
- (void)consentToolViewController:(CMPConsentToolViewController *)consentToolViewController didReceiveConsentString:(NSString*)consentString;
@end

@interface CMPConsentToolViewController : UIViewController


/**
 Optional delegate to receive callbacks from the CMP web tool
 */
@property (nonatomic, weak) id<CMPConsentToolViewControllerDelegate> delegate;
/**
 This listener will be called, if an error occurs while calling the Server or showing the view.
 */
@property (nonatomic, copy) void (^networkErrorListener)(NSString *error);

@end
