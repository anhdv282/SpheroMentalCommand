//
//  HeadsetDevice.m
//  FocusMindChallenge
//
//  Created by Viet Anh on 1/7/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

#import "HeadsetDevice.h"

@implementation HeadsetDevice
-(id)init
{
    self = [super init];
    if (self) {
        self.deviceId = @"";
        self.deviceType = @"";
        self.type = 0;
    }
    return self;
}
@end
