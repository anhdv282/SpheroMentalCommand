//
//  HeadsetDevice.h
//  FocusMindChallenge
//
//  Created by Viet Anh on 1/7/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeadsetDevice : NSObject
@property (strong, nonatomic) NSString *deviceType;
@property (strong, nonatomic) NSString *deviceId;
@property (assign, nonatomic) int type;
@end
