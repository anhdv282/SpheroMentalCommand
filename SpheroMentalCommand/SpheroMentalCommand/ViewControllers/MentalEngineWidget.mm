//
//  EngineWidget.m
//  edkFramework
//
//  Created by Viet Anh on 2/24/15.
//
//

#import "MentalEngineWidget.h"
#import "Iedk.h"
#import "EdfData.h"
#import "IEEGData.h"
#import "EmotivCloudClient.h"
#import "EmotivCloudPrivate.h"
#import "IEmotivProfile.h"
#import "elsrequest.h"
#import "HeadsetDevice.h"
#import "IEmoStatePerformanceMetric.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation MentalEngineWidget

EmoEngineEventHandle eEvent			= IEE_EmoEngineEventCreate();
EmoStateHandle eState				= IEE_EmoStateCreate();
int state                           = 0;
unsigned int userID                 = -1;
unsigned long trainedAction         = 0;
unsigned long activeAction          = 0;
bool isConnected;
bool userAdded;
bool readyToCollect;
int headsetType;

NSString *profilePath;
NSString *currentProfileName;
NSTimer *timer;

//NSMutableArray * arrSignal;
//NSArray *arrAction;

MentalEngineWidget *engine;

+(id) shareInstance {
    if(!engine)
    {
        engine = [[MentalEngineWidget alloc] init];
    }
    return engine;
}

-(id)initForLogin{
    self = [super init];
    if(self)
    {
        [self connectEngine];
    }
    return self;
}

-(id) init {
    self = [super init];
    if(self)
    {
        currentProfileName = @"";
        IEE_EnableDetections(DT_MentalCommand | DT_Excitement | DT_Engagement | DT_Relaxation | DT_Interest | DT_Stress | DT_Focus );
//        [self connectEdfFile];
        [self connectEngine];
        [self initProfileDirectory];
        self.userProfileID = 0;
        isConnected = false;
        userAdded = false;
        readyToCollect = false;
        
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getNextEvent) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
        [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeInactive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

-(void)appDidBecomeInactive:(NSNotification*)noti
{
    [RKRobotDiscoveryAgent stopDiscovery];
    [RKRobotDiscoveryAgent disconnectAll];
}

-(void)appDidBecomeActive:(NSNotification*)noti
{
    [RKRobotDiscoveryAgent startDiscovery];
}

-(void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)noti
{
    switch(noti.type){
        case RKRobotOnline:
        {
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:noti.robot];
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [convenience disconnect];
                return;
            }
            
            self.currentRobot = convenience;
        }
            break;
        case RKRobotConnected:
        {
            if(self.currentRobot == nil){
                RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:noti.robot];
                if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                    [convenience disconnect];
                    return;
                }
                
                self.currentRobot = convenience;
            }
        }
            break;
        case RKRobotOffline:
            break;
        case RKRobotDisconnected:
        {
            self.currentRobot = nil;
            [RKRobotDiscoveryAgent startDiscovery];
        }
            break;
        default:
            break;
    }
    
    if(self.signalDelegate != nil){
        [self.signalDelegate onSpheroStatusUpdated];
    }
    if(self.listDeviceDelegate != nil){
        [self.listDeviceDelegate onSpheroStatusUpdated];
    }
}

-(void) connectEngine
{
    IEE_EmoInitDevice();
    IEE_EngineConnect();
    [self connectCloud];
}

-(void) connectEmoComposer
{
    IEE_EngineRemoteConnect("192.168.1.200", 1726);
}

-(void) connectEdfFile
{
    NSFileManager *fmngr = [[NSFileManager alloc] init];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"newdata.edf" ofType:nil];
    NSError *error;
    NSString *fileDocument = [NSString stringWithFormat:@"%@/Documents/%@",NSHomeDirectory(),@"newdata.edf"] ;
    NSLog(fileDocument);
    if(![fmngr copyItemAtPath:filePath toPath:fileDocument error:&error]) {
        // handle the error
    }
    bool result = IEE_EngineLocalConnect([fileDocument cStringUsingEncoding:NSUTF8StringEncoding], "");
    IEE_EdfStart();
}

-(void) initProfileDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    profilePath = [documentsDirectory stringByAppendingString:@"/Emotiv/Profile"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:profilePath])
        [[NSFileManager defaultManager] createDirectoryAtPath:profilePath withIntermediateDirectories:YES attributes:nil error:nil];
}

#pragma mark Profile Function

-(BOOL) addProfile:(NSString *)name {
    if([self checkProfileIsExisted:name]) {
        return false;
    }
    else {
        //create new profile
        EmoEngineEventHandle eventHandler = IEE_EmoEngineEventCreate();
        IEE_GetBaseProfile(eventHandler);
        unsigned int profileBytes = 0;
        IEE_GetUserProfileSize(eventHandler, &profileBytes);
        unsigned char *profileBuffer = new unsigned char[profileBytes];
        IEE_SetUserProfile(userID, profileBuffer, profileBytes);
        [self saveProfile:name finish:^{}];
        [self setProfile:name];
        return true;
    }
}

-(void) setGuestProfile {
    currentProfileName = @"Guest";
    EmoEngineEventHandle eventHandler = IEE_EmoEngineEventCreate();
    IEE_GetBaseProfile(eventHandler);
    unsigned int profileBytes = 0;
    IEE_GetUserProfileSize(eventHandler, &profileBytes);
    unsigned char *profileBuffer = new unsigned char[profileBytes];
    IEE_SetUserProfile(userID, profileBuffer, profileBytes);
}

-(void) setProfile:(NSString *)name {
    currentProfileName = name;
}

-(NSArray*)getlistProfile{
    NSMutableArray * arrayProfile = [[NSMutableArray alloc] init];
    NSError *error;
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:profilePath error:&error];
    for(int i = 0; i < array.count; i++) {
        NSString *name = [array objectAtIndex:i];
        if([name containsString:@".emu"])
            [arrayProfile addObject:[name stringByReplacingOccurrencesOfString:@".emu" withString:@""]];
    }
    return arrayProfile;
}
        
-(void)saveProfile:(NSString *)name finish:(void(^)())finish{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(![name.lowercaseString  isEqual: @"guest"]) {
            NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", name]];
            IEE_SaveUserProfile(userID, [tempName cStringUsingEncoding:NSUTF8StringEncoding]);
            dispatch_async(dispatch_get_main_queue(), ^{
                finish();
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                finish();
            });
        }
    });
}

-(void) loadProfile:(NSString *)name finish:(void(^)(BOOL result))finish{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", name]];
        
        if(IEE_LoadUserProfile(userID, [tempName cStringUsingEncoding:NSUTF8StringEncoding]) == EDK_OK)
        {
            NSLog(@"end");
            [self setProfile:name];
            [self updateProfileChange];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(true);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false);
            });
        }
    });

}

-(BOOL) checkProfileIsExisted:(NSString *)name {
    NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", name]];
    return [[NSFileManager defaultManager] fileExistsAtPath:tempName];
}

-(void) removeProfile:(NSString *)name finish:(void(^)(BOOL success))finish{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", name]];
        
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:tempName error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            finish(result);
        });
    });
    
    
}

-(NSString *) getProfileName {
    return currentProfileName;
}


#pragma mark - cloud profile new
-(void)checkNewProfileFile:(int)userId profileName:(NSString*)profileName version:(int)currentVersion file:(NSString*)filePath finish:(void (^)(BOOL isSuccess, int lastVersion))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try
        {
            int profileID = 0;
            EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding], &profileID);
            
            if(profileID > 0)
            {
                int lastestVersion = 0;
                EC_GetLastestProfileVersions(userId, profileID, &lastestVersion);
//                EC_GetLastestProfileVersions(userId, profileID, lastestVersion);
                
                if(currentVersion == 0 || (currentVersion < lastestVersion))
                {
                    int result = EC_DownloadProfileFile(userId, profileID, [filePath cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    if(result == EDK_OK)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            finish(true, lastestVersion);
                        });
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            finish(false, lastestVersion);
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        finish(false, currentVersion);
                    });
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish(false, 0);
                });
            }
        }
        @catch (NSException *exception)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false, 0);
            });
        }
    });
}

-(void)newAddProfile:(int)userId profileName:(NSString *)profileName success:(void (^)(int result))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if([self checkProfileIsExisted:profileName]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(-1);
            });
        }
        else {
            //create new profile
            EmoEngineEventHandle eventHandler = IEE_EmoEngineEventCreate();
            IEE_GetBaseProfile(eventHandler);
            unsigned int profileBytes = 0;
            IEE_GetUserProfileSize(eventHandler, &profileBytes);
            unsigned char *profileBuffer = new unsigned char[profileBytes];
            IEE_SetUserProfile(userID, profileBuffer, profileBytes);
            [self saveProfile:profileName finish:^{}];
            [self setProfile:profileName];
            
            NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", profileName]];
            
            if(IEE_SaveUserProfile(userID, [tempName cStringUsingEncoding:NSUTF8StringEncoding]) == EDK_OK && EC_UploadProfileFile(userId, [profileName cStringUsingEncoding:NSUTF8StringEncoding], [tempName cStringUsingEncoding:NSUTF8StringEncoding], TRAINING) == EDK_OK)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish(1); // all done
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish(0); //fail to create cloud profile
                });
            }
        }
    });
}

-(void)newLoadProfile:(int)userId :(NSString*)profileName version:(int)currentVersion success:(void (^)(BOOL isSuccess, int newVersion))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", profileName]];
        
        [self checkNewProfileFile:userId profileName:profileName version:currentVersion file:tempName finish:^(BOOL isSuccess, int latestVersion) {
            if(IEE_LoadUserProfile(userID, [tempName cStringUsingEncoding:NSUTF8StringEncoding]) == EDK_OK)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProfile:profileName];
                    [self updateProfileChange];
                    finish(true, latestVersion);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish(false, latestVersion);
                });
            }
        }];
    });
}

-(void)newSaveProfile:(int)userId profileName:(NSString*)profileName success:(void (^)(int result, int latestVersion))finish
{
    if(![profileName.lowercaseString  isEqual: @"guest"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", profileName]];
            if(IEE_SaveUserProfile(userID, [tempName cStringUsingEncoding:NSUTF8StringEncoding]) == EDK_OK)
            {
                int profileID = 0;
                EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding], &profileID);
                if(profileID > 0)
                {
                    int result = EC_UpdateUserProfile(userId, 0, profileID);
                    
                    int lastestVersion = 0;
                    EC_GetLastestProfileVersions(userId, profileID, &lastestVersion);
                    
                    if(result == EDK_OK)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            finish(1, lastestVersion); ///all success
                        });
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            finish(0, lastestVersion); ///success to save to local but fail to upload cloud
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        finish(0, 0); ///success to save to local but fail to upload cloud
                    });
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish(-1, 0); ///fail to save file to local
                });
            }
        });
    }
}

//-(void) newRemoveProfile:(int)userId profileName:(NSString *)profileName success:(void (^)(BOOL result))finish
//{
//    NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", profileName]];
//    [self.signalDelegate removeProfile:[[NSFileManager defaultManager] removeItemAtPath:tempName error:nil]];
//    
//    if(![profileName.lowercaseString  isEqual: @"guest"]) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//            NSString *tempName = [profilePath stringByAppendingString:[NSString stringWithFormat:@"/%@.emu", profileName]];
//            if([[NSFileManager defaultManager] removeItemAtPath:tempName error:nil])
//            {
//                int profileId = EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding]);
//                if(profileId > 0)
//                {
//                    int result = EC_DeleteUserProfile(userID, profileId);
//                    
//                    if(result == EDK_OK)
//                    {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            finish(1); ///all success
//                        });
//                    }
//                    else
//                    {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            finish(0); ///success to save to local but fail to upload cloud
//                        });
//                    }
//                }
//                else
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        finish(0); ///success to save to local but fail to upload cloud
//                    });
//                }
//            }
//            else
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    finish(-1); ///fail to save file to local
//                });
//            }
//        });
//    }
//}

#pragma mark - cloud profile

-(void) getListProfile:(int)userID success:(void (^)(NSArray* result))success fail:(void (^)(NSString* message))fail
{
    NSMutableArray * arrayProfile = [[NSMutableArray alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            int profileCount = 0;
            profileCount = EC_GetAllProfileName(userID);
            
            
            for(int i = 0; i < profileCount; i++)
            {
                [arrayProfile addObject:[NSString stringWithFormat:@"%s", EC_ProfileNameAtIndex(userID, i)]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                success(arrayProfile);
            });
        }
        @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                fail(exception.description);
            });
        }
    });
}

-(void)loadProfile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            int profileID = 0;
            EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding], &profileID);
            int result = EC_LoadUserProfile(userID, 0, profileID);
            
            [self updateProfileChange];
            [self setProfile:profileName];
            
            if(result != EDK_OK)
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"load profile fail profile %@", profileName);
                    finish(false);
                });
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"load profile success profile %@", profileName);
                    finish(true);
                });
            }
        }
        @catch (NSException *exception)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false);
            });
        }
    });
}

-(void)uploadProfileFile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            
            int result = EC_SaveUserProfile(userID, 0, [profileName cStringUsingEncoding:NSASCIIStringEncoding], TRAINING);
            
            [self updateProfileChange];
            [self setProfile:profileName];
            
            if(result != EDK_OK)
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Create profile fail profile %@", profileName);
                    finish(false);
                });
            else
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Create profile success profile %@", profileName);
                    finish(true);
                });
        }
        @catch (NSException *exception)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false);
            });
        }
    });
}

-(void)deleteProfile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            int profileID = 0;
            EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding], &profileID);
            int result = EC_DeleteUserProfile(userID, profileID);
            
            if(result != EDK_OK)
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Delete profile fail profile %@", profileName);
                    finish(false);
                });
            else
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Delete profile success profile %@", profileName);
                    finish(true);
                });
        }
        @catch (NSException *exception)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false);
            });
        }
    });
}

-(void)updateProfile:(int) userID profileName:(NSString*)profileName filePath:(NSString*)filePath finish:(void (^)(BOOL isSuccess))finish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            int profileID = 0;
            EC_GetProfileId(userID, [profileName cStringUsingEncoding:NSASCIIStringEncoding], &profileID);
            int result = EC_UpdateUserProfile(userID, 0, profileID);
            
            if(result != EDK_OK)
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Save profile fail profile %@", profileName);
                    finish(false);
                });
            else
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Save profile success profile %@", profileName);
                    finish(true);
                });
        }
        @catch (NSException *exception)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(false);
            });
        }
    });
}
#pragma mark Engine Function

-(NSArray*) getListDevice {
    NSMutableArray *listDevice = [[NSMutableArray alloc] init];
    HeadsetDevice *device;
    if (IEE_GetInsightDeviceCount() != 0 || IEE_GetEpocPlusDeviceCount() != 0) {
        for (int i = 0; i < IEE_GetInsightDeviceCount(); i++) {
            //            NSLog(@"Insight name: %s at %d",IEE_GetNameDeviceInsightAtIndex(i),i);
            NSString *nameDeviceInsight = [NSString stringWithFormat:@"%s",IEE_GetInsightDeviceName(i)];
            device = [[HeadsetDevice alloc] init];
            device.deviceType = @"Emotiv Insight";
            @try {
                device.deviceId = [[[[nameDeviceInsight componentsSeparatedByString:@"("] objectAtIndex:1] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
            } @catch (NSException *exception) {
                
            }
            
            device.type = 0;
            [listDevice addObject:device];
        }
        for (int j = 0; j < IEE_GetEpocPlusDeviceCount(); j++) {
            //            NSLog(@"EPOC name: %s at %d",EE_GetNameDeviceEpocAtIndex(j),j);
            NSString *nameDeviceEpoc = [NSString stringWithFormat:@"%s",IEE_GetEpocPlusDeviceName(j)];
            device = [[HeadsetDevice alloc] init];
            device.deviceType = @"Emotiv Epoc";
            @try {
                device.deviceId = [[[[nameDeviceEpoc componentsSeparatedByString:@"("] objectAtIndex:1] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
            } @catch (NSException *exception) {
                
            }
            device.type = 1;
            [listDevice addObject:device];
        }
    }
    return  listDevice;
}
-(BOOL) connnectDevice:(int)headsetNumber type:(int)type {
    headsetType = type;
    BOOL result = false;
    if (type == 0)
        result = IEE_ConnectInsightDevice(headsetNumber);
#ifndef DEVAPP
    else
        result = IEE_ConnectEpocPlusDevice(headsetNumber);
#endif
    return result;
}

-(void) setTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timeOut) userInfo:nil repeats:NO];
}

-(void) timeOut {
//    isConnected = false;
    [timer invalidate];
}

-(void) getNextEvent {

    [self.listDeviceDelegate reloadListDevice:[self getListDevice]];
    
    state = IEE_EngineGetNextEvent(eEvent);
    if(state == EDK_OK)
    {
        IEE_Event_t eventType = IEE_EmoEngineEventGetType(eEvent);
        int result = IEE_EmoEngineEventGetUserId(eEvent, &userID);
        
        if (result != EDK_OK) {
            NSLog(@"WARNING : Failed to return a valid user ID for the current event");
        }
        
        if(eventType == IEE_EmoStateUpdated ) {
            
            IEE_EmoEngineEventGetEmoState(eEvent, eState);
            IEE_MentalCommandAction_t action = IS_MentalCommandGetCurrentAction(eState);
            float power = IS_MentalCommandGetCurrentActionPower(eState);
            
            int valueAF3 = IS_GetContactQuality(eState, IEE_CHAN_AF3);
            int valueAF4 = IS_GetContactQuality(eState, IEE_CHAN_AF4);
            int valueT7 = IS_GetContactQuality(eState, IEE_CHAN_T7);
            int valueT8 = IS_GetContactQuality(eState, IEE_CHAN_T8);
            int valuePz = IS_GetContactQuality(eState, IEE_CHAN_Pz);
            
            int chargeLevel = 0;
            int maxChargeLevel = 0;
            IS_GetBatteryChargeLevel(eState, &chargeLevel, &maxChargeLevel);
            
            if(self.engineDelegate)
                [self.engineDelegate emoStateUpdate:(MentalAction_t)action power:power];
            
            if(self.performanceMatrixDelete != nil)
                [self.performanceMatrixDelete updateValue:IS_PerformanceMetricGetRelaxationScore(eState) :IS_PerformanceMetricGetEngagementBoredomScore(eState) :IS_PerformanceMetricGetInstantaneousExcitementScore(eState) :IS_PerformanceMetricGetExcitementLongTermScore(eState) :IS_PerformanceMetricGetInterestScore(eState) :IS_PerformanceMetricGetStressScore(eState)];
            
            if(self.signalDelegate) {
                [self.signalDelegate  getSignalChanels:valueAF3 af4Channel:valueAF4 t7Channel:valueT7 t8Channel:valueT8 pzChannel:valuePz];
                [self.signalDelegate getBatteryData:chargeLevel maxValue:maxChargeLevel];
            }

            
        }
        if(eventType == IEE_UserAdded)
        {
            NSLog(@"User Added");
            userAdded = true;
            isConnected = true;
            readyToCollect = true;
            IEE_DataAcquisitionEnable(userID, true);
            if(self.engineDelegate)
               [self.engineDelegate onHeadsetConnected:userID];
            if(self.signalDelegate)
                [self.signalDelegate onHeadsetConnected:userID];
        }
        if(eventType == IEE_UserRemoved){
            NSLog(@"user remove");
            isConnected = false;
            userAdded = false;
            readyToCollect = false;
            IEE_DataAcquisitionEnable(userID, false);
            if(self.engineDelegate)
                [self.engineDelegate onHeadsetRemoved:userID];
            if(self.signalDelegate)
                [self.signalDelegate onHeadsetRemoved:userID];
        }
        if(eventType == IEE_MentalCommandEvent) {
            IEE_MentalCommandEvent_t mcevent = IEE_MentalCommandEventGetType(eEvent);
            switch (mcevent) {
                case IEE_MentalCommandTrainingCompleted:
                    [self updateProfileChange];
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingCompleted:[self getSelectedHeadsetID]];
                    NSLog(@"complete");
                    break;
                case IEE_MentalCommandTrainingStarted:
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingStarted:[self getSelectedHeadsetID]];
                    NSLog(@"start");
                    break;
                case IEE_MentalCommandTrainingFailed:
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingFailed:[self getSelectedHeadsetID]];
                    NSLog(@"fail");
                    break;
                case IEE_MentalCommandTrainingSucceeded:
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingSucceeded:[self getSelectedHeadsetID]];
                    NSLog(@"success");
                    break;
                case IEE_MentalCommandTrainingRejected:
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingRejected:[self getSelectedHeadsetID]];
                    NSLog(@"reject");
                    break;
                case IEE_MentalCommandTrainingDataErased:
                    [self updateProfileChange];
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandTrainingDataErased:[self getSelectedHeadsetID]];
                    NSLog(@"erased");
                    break;
                case IEE_MentalCommandSignatureUpdated:
                    [self updateProfileChange];
                    if(self.engineDelegate)
                        [self.engineDelegate onMentalCommandSignatureUpdated:[self getSelectedHeadsetID]];
                    NSLog(@"update signature");
                default:
                    break;
            }
        }
        if (readyToCollect == true) {
            int Xout = 0;
            int Yout = 0;
            IEE_HeadsetGetGyroDelta(userID, &Xout, &Yout);
            
            float result = 0;
            const float PI = 3.141592653589f;
            Xout = 0;
            if ( abs(Xout) > 20 || abs(Yout) > 20 ) {
                if( Xout == 0 && Yout != 0 ) {
                    if (Yout > 0)
                        result = 180;
                    else
                        result = 0;
                }
                else if( Xout != 0 && Yout == 0 ) {
                    if (Xout > 0)
                        result = 270;
                    else
                        result = 90;
                }
                else {
                    result = atan(Yout / (float)Xout) * 180 / PI;
                    
                    if (Xout > 0) {
                        if (Yout > 0) {
                        }
                        else
                            result = 360 + result;
                    }
                    else {
                        if (Yout > 0)
                            result = 180 + result;
                        else
                            result += 180;
                    }
                    
                    result = result - 270;
                    
                    if (result < 0)
                        result = -result;
                    else
                        result = 360 - result;
                }
                if(self.engineDelegate) {
                    [self.engineDelegate getAngleData:result];
                }
//                NSLog(@"%d %d %f", Xout, Yout, result);
            }
        }
    }
}

-(void)connectCloud
{
//    dispatch_async(dispatch_get_main_queue(), ^{
        EC_Connect();
        EC_EnableCloudThread();
        NSString *userAgent = [NSString stringWithFormat:@"MentalCommands App version %@; iOS %@; %@",
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                               [[UIDevice currentDevice] systemVersion], [self getPlatformString]];
        int setAgentResult;
        setAgentResult = EC_SetUserAgent([userAgent cStringUsingEncoding:NSUTF8StringEncoding]);
//    });
}

-(void) updateProfileChange
{
    IEE_MentalCommandGetTrainedSignatureActions(userID, &trainedAction);
    IEE_MentalCommandGetActiveActions(userID, &activeAction);
    //optional
//    [self saveProfile:profileName];
}

-(void) loginWithGuest {
    EC_LoginAsGuest(0);
}

-(void) loginWithUserName : (NSString *) userName Password : (NSString*) password success:(void (^)(int userid))success fail:(void (^)(NSString* message))fail {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            int result = EC_Login([userName cStringUsingEncoding:NSUTF8StringEncoding], [password cStringUsingEncoding:NSUTF8StringEncoding]);
            if(result != EDK_OK) {
                EC_Connect();
                dispatch_async(dispatch_get_main_queue(), ^{
                    fail([NSString stringWithFormat:@"Your EmotivID: %@ or your password was not recognized, please try again.", userName]);
                    //                [self.delegate requestFail:[NSString stringWithFormat:@"Your EmotivID: %@ or your password was not recognized, please try again.", userName] RequestType:REQUEST_LOGIN];
                    //[self.delegate requestFail:@"Your authentication information was incorrect!" RequestType:REQUEST_LOGIN];
                });
            }
            else {
                int userID = 0;
                int result = EC_GetUserDetail(&userID);
                if(result == EDK_OK) {
//                    char * response = NULL;
                    userID = EC_GetDefaultUser();
//                    ELS_GetResponseString(userID, 1, &response);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(userID);
                    });
                }
                else
                    dispatch_async(dispatch_get_main_queue(), ^{
                        fail(@"");
                    });
            }
        }
        @catch (NSException *exception) {
            NSLog(@"login exception %@", exception.description);
        }
    });
}

-(void) logout : (int) userID {
    @try {
        EC_Logout(userID);
    }
    @catch (NSException *exception) {
        
    }
}

-(void) setActiveAction : (MentalAction_t) action
{
    if(!(activeAction & action) && action != Mental_Neutral) {
        activeAction = activeAction | action;
        IEE_MentalCommandSetActiveActions(userID, activeAction);
    }
}

-(void) setDeActiveAction : (MentalAction_t) action
{
    if ([self isActionActive:action] && action != Mental_Neutral){
        
        activeAction = activeAction & (~action);
        IEE_MentalCommandSetActiveActions(userID, activeAction);
    }
}


-(bool) setTrainingAction : (MentalAction_t) action
{
    int status = IEE_MentalCommandSetTrainingAction(userID, (IEE_MentalCommandAction_t)action);
    return status == EDK_OK;
}

-(bool) setTrainingControl : (MentalControl_t) control
{
    int status = IEE_MentalCommandSetTrainingControl(userID, (IEE_MentalCommandTrainingControl_t)control);
    return status == EDK_OK;
}

-(BOOL) abortTrainingData : (MentalAction_t) action{
    if(IEE_MentalCommandSetTrainingControl(userID, (IEE_MentalCommandTrainingControl_t)MC_RESET) == EDK_OK)
    {
        return true;
    }
    return false;
}

-(void) clearTrainingData : (MentalAction_t) action
{
    if (IEE_MentalCommandSetTrainingAction(userID, (IEE_MentalCommandAction_t) action) != EDK_OK) {
        NSLog(@"Fail to clear training data. Algorithm is deactivated due to optimization");
        return;
    }
    if (IEE_MentalCommandSetTrainingControl(userID, (IEE_MentalCommandTrainingControl_t)MC_ERASE) == EDK_OK) {
        
    }else{
        NSLog(@"Fail to abort training. Algorithm is deactivated due to optimization");
    }
}

-(bool) getActionSkillRating:(int)headsetID Action:(MentalAction_t)action ActionSkillRatingOut:(float *)pActionSkillRatingOut {
    assert(pActionSkillRatingOut);
    int status = 0;
    status = IEE_MentalCommandGetActionSkillRating(userID, (IEE_MentalCommandAction_t)action, pActionSkillRatingOut);
    return status;
}

-(bool) getTrainingTime:(int)headsetID TrainingTimeOut:(unsigned int *)pTrainingTimeOut {
    assert(pTrainingTimeOut);
    int status = 0;
    status = IEE_MentalCommandGetTrainingTime(headsetID, pTrainingTimeOut);
    return status == EDK_OK;
}


-(BOOL) isActionTrained : (MentalAction_t) action
{
    return (trainedAction & action)  == action;
}

-(BOOL) isActionActive : (MentalAction_t) action
{
//    NSLog(@"%lu", activeAction & action);
    if(action == Mental_Neutral)
        return true;
    return (activeAction & action) == action;
}


-(BOOL) isHeadsetConnected {
    return isConnected;
}

-(int) getSelectedHeadsetID {
    return userID;
}

-(NSString *) getPlatformString {
    NSString* deviceName;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    if ([platform isEqualToString:@"iPhone1,1"])    deviceName =  @"iPhone 2G";
    if ([platform isEqualToString:@"iPhone1,2"])    deviceName =  @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    deviceName =  @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    deviceName =  @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"])    deviceName =  @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    deviceName =  @"iPhone 4 (CDMA)";
    if ([platform isEqualToString:@"iPhone4,1"])    deviceName =  @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    deviceName =  @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"])    deviceName =  @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    deviceName =  @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone5,4"])    deviceName =  @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    deviceName =  @"iPhone 5S";
    if ([platform isEqualToString:@"iPhone6,2"])    deviceName =  @"iPhone 5S (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,1"])    deviceName =  @"iPhone 6 Plus (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    deviceName =  @"iPhone 6 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone8,1"])    deviceName =  @"iPhone 6s";
    if ([platform isEqualToString:@"iPhone8,2"])    deviceName =  @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPod1,1"])      deviceName =  @"iPod Touch (1 Gen)";
    if ([platform isEqualToString:@"iPod2,1"])      deviceName =  @"iPod Touch (2 Gen)";
    if ([platform isEqualToString:@"iPod3,1"])      deviceName =  @"iPod Touch (3 Gen)";
    if ([platform isEqualToString:@"iPod4,1"])      deviceName =  @"iPod Touch (4 Gen)";
    if ([platform isEqualToString:@"iPod5,1"])      deviceName =  @"iPod Touch (5 Gen)";
    
    if ([platform isEqualToString:@"iPad1,1"])      deviceName =  @"iPad ";
    if ([platform isEqualToString:@"iPad1,2"])      deviceName =  @"iPad 3G";
    if ([platform isEqualToString:@"iPad2,1"])      deviceName =  @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      deviceName =  @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])      deviceName =  @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      deviceName =  @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])      deviceName =  @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      deviceName =  @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,7"])      deviceName =  @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      deviceName =  @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      deviceName =  @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      deviceName =  @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])      deviceName =  @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      deviceName =  @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])      deviceName =  @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      deviceName =  @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      deviceName =  @"iPad Air (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,3"])      deviceName =  @"iPad Air (GSM+CDMA/China)";
    if ([platform isEqualToString:@"iPad4,4"])      deviceName =  @"iPad Mini 2 (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      deviceName =  @"iPad Mini 2 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,6"])      deviceName =  @"iPad Mini 2 (GSM+CDMA/China)";
    if ([platform isEqualToString:@"iPad4,7"])      deviceName =  @"iPad Mini 3 (WiFi)";
    if ([platform isEqualToString:@"iPad4,8"])      deviceName =  @"iPad Mini 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,8"])      deviceName =  @"iPad Mini 3 (GSM+CDMA/China)";
    if ([platform isEqualToString:@"iPad5,3"])      deviceName =  @"iPad Air 2 (WiFi)";
    if ([platform isEqualToString:@"iPad5,4"])      deviceName =  @"iPad Air 2 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"i386"])         deviceName =  @"Simulator 32";
    if ([platform isEqualToString:@"x86_64"])       deviceName = @"Simulator 64";
    
    return deviceName;
}


@end
