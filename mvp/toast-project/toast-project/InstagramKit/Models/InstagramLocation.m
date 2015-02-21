//
//  InstagramLocation.m
//  toast-project
//
//  Created by Diego Cruz on 2/12/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

#import "InstagramLocation.h"

@implementation InstagramLocation

- (id)initWithInfo:(NSDictionary *)info
{
    self = [super initWithInfo:info];
    if (self && IKNotNull(info)) {
        
        _name = [[NSString alloc] initWithString:info[@"name"]];
        _instagramId = [[NSString alloc] initWithString:info[@"id"]];
        _location = CLLocationCoordinate2DMake(((NSNumber *)info[@"latitude"]).doubleValue, ((NSNumber *)info[@"longitude"]).doubleValue);
        
    }
    return self;
}
@end
