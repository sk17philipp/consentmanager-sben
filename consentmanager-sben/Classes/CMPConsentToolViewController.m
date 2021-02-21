//
//  CMPConsentToolViewController.m
//  GDPR
//

#import "CMPConsentToolViewController.h"
#import "CMPDataStorageV1UserDefaults.h"
#import "CMPDataStorageV2UserDefaults.h"
#import "CMPDataStorageConsentManagerUserDefaults.h"
#import "CMPActivityIndicatorView.h"
#import "CMPConsentToolUtil.h"
#import "CMPConfig.h"
#import "CMPSettings.h"
#import "CMPServerResponse.h"
#import <WebKit/WebKit.h>

NSString *const ConsentStringQueryParam = @"code64";
NSString *const ConsentStringPrefix = @"consent://";

@interface CMPConsentToolViewController ()<WKNavigationDelegate>
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) CMPActivityIndicatorView *activityIndicatorView;
@property (nonatomic, retain) CMPServerResponse *cmpServerResponse;
@end

@implementation CMPConsentToolViewController
static bool error = FALSE;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    if (@available(iOS 13.0, *)) {
        [self setModalInPresentation:TRUE];
    } else {
        [self setModalPresentationStyle:UIModalPresentationFullScreen];
    }
    
    [self initWebView];
    
    if( ! error ){
      [self initActivityIndicator];
    }

    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
    error = false;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
     return NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSURLRequest *request = [self requestForConsentTool:10];
    if (request) {
        [_webView loadRequest:request];
    }
    if( error ){
        [super dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [_activityIndicatorView removeFromSuperview];
    NSLog(@"Failed to load consentScreen");
    if( _networkErrorListener ){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self->_networkErrorListener(@"Failed to load URL");
        });
        
    }
}


-(void)initWebView {

    if( ![CMPSettings consentToolUrl] || [[CMPSettings consentToolUrl] isEqualToString:@""]){
        NSLog(@"CMPSettingsAreInvalid");
        error = true;
        return;
    }

    if( [CMPConsentToolUtil isNetworkAvailable] && !error){
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.scrollView.scrollEnabled = YES;
        _webView.accessibilityViewIsModal = FALSE;
        [self.view addSubview:_webView];
        [self layoutWebView];
        
    } else {
        if( _networkErrorListener ){
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                self->_networkErrorListener(@"The Network is not reachable to show the WebView");
            });
            
        }
        [_activityIndicatorView removeFromSuperview];
        error = true;
        NSLog(@"Network is not reachable");
    }

}

-(void)layoutWebView {
    _webView.translatesAutoresizingMaskIntoConstraints = NO;

    if (@available(iOS 11, *)) {
        UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor],
                                                  [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
                                                  [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
                                                  [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor]
                                                  ]];
    } else {
        id topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_webView, topAnchor);

        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[topGuide]-[_webView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:viewsDictionary]];

        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-0-[_webView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:viewsDictionary]];    }
}

-(void)initActivityIndicator {
    _activityIndicatorView = [[CMPActivityIndicatorView alloc] initWithFrame:self.view.frame];
    _activityIndicatorView.userInteractionEnabled = NO;
    [self.view addSubview:_activityIndicatorView];
    [_activityIndicatorView startAnimating];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    NSURLRequest *request = navigationAction.request;
    
    // new base64-encoded consent string received
    if ([request.URL.absoluteString.lowercaseString hasPrefix:ConsentStringPrefix]) {
        NSString *newConsentString = [self consentStringFromRequest:request];

        if ([self.delegate respondsToSelector:@selector(consentToolViewController:didReceiveConsentString:)]) {
            [self.delegate consentToolViewController:self didReceiveConsentString:newConsentString];
        }
    } else if(request.URL.absoluteString.lowercaseString.length > 0 && ![request.URL.absoluteString isEqualToString:[self requestForConsentTool:10].URL.absoluteString] && ! [request.URL.absoluteString containsString: @"about:blank"]){
        [[UIApplication sharedApplication] openURL:request.URL options:@{} completionHandler:nil];
    }

    decisionHandler(policy);
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_activityIndicatorView stopAnimating];
    if( _networkErrorListener ){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            self->_networkErrorListener(@"Timeout has been reached");
        });
        
    }
}

-(NSURLRequest*)requestForConsentTool:(long)timeout{
    if ([CMPSettings consentToolUrl]) {
        NSMutableURLRequest* request;
        if ([CMPSettings consentString] && [[CMPSettings consentString] length] > 0) {
             request = [NSMutableURLRequest requestWithURL:[self addConsentParamToUrl:[CMPSettings consentToolUrl] withConsent:[CMPSettings consentString]]];
             
        } else {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[CMPSettings consentToolUrl]]];
        }
        request.timeoutInterval = timeout;
        NSLog(@"Opening View with url: %@", [CMPSettings consentToolUrl]);
        
        return request;
    }
    return nil;
}

-(NSString*)consentStringFromRequest:(NSURLRequest *)request {
    NSRange consentStringRange = [request.URL.absoluteString rangeOfString:ConsentStringPrefix options:NSBackwardsSearch];
    if (consentStringRange.location != NSNotFound) {
        NSString *responseString = [request.URL.absoluteString substringFromIndex:consentStringRange.location + consentStringRange.length];
        NSArray *response = [responseString componentsSeparatedByString:@"/"];
        NSString *consentString = response.firstObject;
        return consentString;
    }

    return nil;
}



-(NSURL *)addConsentParamToUrl:(NSString *)consentToolUrl withConsent:(NSString *)consent {
    if( [consentToolUrl containsString:@"consent=&"]){
        NSMutableString *paramString = [NSMutableString new];
        [paramString appendString:@"consent="];
        [paramString appendString:consent];
        
        NSString *consentToolUrlWithConsent = [consentToolUrl stringByReplacingOccurrencesOfString:@"consent=" withString:paramString];
        NSURL *url = [NSURL URLWithString:consentToolUrlWithConsent];
        NSLog(@"Opening View with url: %@", [url absoluteString]);
        return url;
    }
    NSURL *url = [NSURL URLWithString:consentToolUrl];
    NSLog(@"Opening View with url: %@", [url absoluteString]);
    return url;
}

@end
