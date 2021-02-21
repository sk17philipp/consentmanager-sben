//
//  PublisherRestrictionTypeValue.m
//  GDPR
//

#import "PublisherRestrictionTypeValue.h"

@implementation PublisherRestrictionTypeValue

@synthesize restrictionType;
@synthesize vendorIds;


-(id)init:(int)rType vendors:(NSString*) vIds{
    restrictionType = rType;
    vendorIds = vIds;
    return self;
}

- (NSString *)vendorIds{
    return vendorIds;
}

- (int)restrictionType{
    return restrictionType;
}

- (void)setVendorIds:(NSString *)vId{
    vendorIds = vId;
}

- (void)setRestrictionType:(int)rType{
    restrictionType = rType;
}

- (BOOL)hasVendorId:(int)vId{
    if([vendorIds length] < vId || vId <= 0){
        return FALSE;
    }
    if( ![[vendorIds substringWithRange:NSMakeRange((vId - 1), 1)] isEqualToString:@"0"]){
        return TRUE;
    }
    return FALSE;
}
@end
