//
//  EngineWidget.h
//  edkFramework
//
//  Created by Viet Anh on 2/24/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <RobotKit/RobotKit.h>

typedef enum TrainAction_enum
{
    Train_Disable,
    Train_Clear,
    Train_Re,
} TrainAction_t;

typedef enum MentalControl_enum
{
    Mental_None,
    Mental_Start,
    Mental_Accept,
    Mental_Reject,
    Mental_Erase,
    Mental_Reset
} MentalControl_t;

typedef enum MentalAction_enum
{
    Mental_Neutral						= 0x0001,
    Mental_Push						= 0x0002,
    Mental_Pull						= 0x0004,
    Mental_Lift						= 0x0008,
    Mental_Drop						= 0x0010,
    Mental_Left						= 0x0020,
    Mental_Right						= 0x0040,
    Mental_Rotate_Left					= 0x0080,
    Mental_Rotate_Right				= 0x0100,
    Mental_Rotate_Clockwise			= 0x0200,
    Mental_Rotate_Counter_Clockwise	= 0x0400,
    Mental_Rotate_Forwards				= 0x0800,
    Mental_Rotate_Reverse				= 0x1000,
    Mental_Disappear					= 0x2000
} MentalAction_t;

@protocol SelectHeadsetDelegate <NSObject>

/*list device delegate*/
-(void) reloadListDevice: (NSArray *) array;

-(void)onSpheroStatusUpdated;

@end

@protocol MentalEngineWidgetDelegate <NSObject>

@optional

- (void) emoStateUpdate : (MentalAction_t) currentAction power : (float) currentPower;

- (void) onMentalCommandTrainingTriggered : (bool) inTraining;
- (void) onMentalCommandTrainingStarted : (int) headsetID;
- (void) onMentalCommandTrainingSucceeded : (int) headsetID;
- (void) onMentalCommandTrainingFailed : (int) headsetID;
- (void) onMentalCommandTrainingCompleted : (int) headsetID;
- (void) onMentalCommandTrainingDataErased : (int) headsetID;
- (void) onMentalCommandTrainingRejected : (int) headsetID;
- (void) onMentalCommandTrainingReset : (int) headsetID;
- (void) onMentalCommandNeutralSamplingCompleted : (int) headsetID;
- (void) onMentalCommandSignatureUpdated : (int) headsetID;
- (void) onHeadsetConnected:(int)headsetID;
- (void) onHeadsetRemoved:(int)headsetID;

-(void)onSpheroStatusUpdated;

-(void) updateValue : (float)relaxationScore : (float)boredScore : (float) exciteScore : (float) longExciteScore : (float) interestScore : (float) stressScore;

//signal delegate
-(void ) getSignalChanels: (int) valueSignalAF3 af4Channel : (int) valueSignalAF4 t7Channel : (int) valueSignalT7 t8Channel : (int) valueSignalT8 pzChannel : (int) valueSignalPz;
-(void) getBatteryData : (int) value maxValue:(int)maxValue;
-(void) getAngleData : (int) value;

@end



@interface MentalEngineWidget : NSObject

@property(nonatomic, strong) id<MentalEngineWidgetDelegate> engineDelegate;
@property(nonatomic, strong) id<MentalEngineWidgetDelegate> signalDelegate;
@property(nonatomic, strong) id<MentalEngineWidgetDelegate> performanceMatrixDelete;
@property(strong, nonatomic) id<SelectHeadsetDelegate> listDeviceDelegate;

+(id) shareInstance;

@property (nonatomic) int userProfileID;

@property (nonatomic, strong) RKConvenienceRobot *currentRobot;

-(id)initForLogin;

-(NSString*) getProfileName;
-(void) setGuestProfile;

-(BOOL) checkProfileIsExisted : (NSString *)name;

-(void) setActiveAction : (MentalAction_t) action;
-(void) setDeActiveAction : (MentalAction_t) action;

-(bool) setTrainingAction : (MentalAction_t) action;

-(bool) setTrainingControl : (MentalControl_t) control;

-(void) clearTrainingData : (MentalAction_t) action;

-(BOOL) abortTrainingData : (MentalAction_t) action;

-(bool) getActionSkillRating:(int)headsetID Action:(MentalAction_t)action ActionSkillRatingOut:(float *)pActionSkillRatingOut;

-(bool) getTrainingTime : (int)headsetID TrainingTimeOut:(unsigned int *)pTrainingTimeOut;

-(BOOL) isActionTrained : (MentalAction_t) action;
-(BOOL) isActionActive : (MentalAction_t) action;


-(BOOL) isHeadsetConnected;

-(int) getSelectedHeadsetID;

-(void) getListProfile:(int)userID success:(void (^)(NSArray* result))success  fail:(void (^)(NSString* message))fail;

-(void) loginWithUserName : (NSString *) userName Password : (NSString*) password success:(void (^)(int userid))success fail:(void (^)(NSString* message))fail;

-(void)uploadProfileFile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish;

-(void)deleteProfile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish;

-(void)loadProfile:(int) userID profileName:(NSString*)profileName finish:(void (^)(BOOL isSuccess))finish;

-(void)updateProfile:(int) userID profileName:(NSString*)profileName filePath:(NSString*)filePath finish:(void (^)(BOOL isSuccess))finish;

-(void) logout : (int) userID;

-(void) loginWithGuest ;

-(NSArray*)getlistProfile;

-(void) loadProfile:(NSString *)name finish:(void(^)(BOOL result))finish;

-(void)saveProfile:(NSString *)name finish:(void(^)())finish;

-(BOOL) addProfile:(NSString *)name;


-(void) removeProfile:(NSString *)name finish:(void(^)(BOOL success))finish;

#pragma mark - new cloud function

-(void)newLoadProfile:(int)userId :(NSString*)profileName version:(int)currentVersion success:(void (^)(BOOL isSuccess, int newVersion))finish;

-(void)newSaveProfile:(int)userId profileName:(NSString*)profileName success:(void (^)(int result, int latestVersion))finish;

-(void)newRemoveProfile:(int)userId profileName:(NSString *)profileName success:(void (^)(BOOL result))finish;

-(void)newAddProfile:(int)userId profileName:(NSString *)profileName success:(void (^)(int result))finish;


#pragma mark - select headset
-(BOOL) connnectDevice:(int)headsetNumber type:(int)type;
-(NSArray*) getListDevice;
-(void) setTimer;

@end
