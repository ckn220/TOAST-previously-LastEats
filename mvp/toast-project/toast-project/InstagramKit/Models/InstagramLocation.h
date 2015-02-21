//
//  InstagramLocation.h
//  toast-project
//
//  Created by Diego Cruz on 2/12/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

#import "InstagramModel.h"
#import <CoreLocation/CoreLocation.h>

@interface InstagramLocation : InstagramModel

@property (nonatomic, readonly) NSString* instagramId;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) CLLocationCoordinate2D location;

@end
