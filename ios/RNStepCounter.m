#import "RNStepCounter.h"
#import "SOMotionDetecter.h"

#import <CoreMotion/CoreMotion.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>

@interface RNStepCounter ()
@property (nonatomic, readonly) CMPedometer *pedometer;
@end

@implementation RNStepCounter
+ (BOOL)requiresMainQueueSetup {
    return YES;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"StepCounter.stepCounterUpdate",
        @"StepCounter.stepDetected",
        @"StepCounter.errorOccurred"
    ];
}

RCT_EXPORT_METHOD(isStepCountingSupported:(RCTPromiseResolveBlock)resolve
                                   reject:(RCTPromiseRejectBlock)reject) {
    resolve(@{@"granted": @(self.authorizationStatus),
            @"supported": @([CMPedometer isStepCountingAvailable]),
                 @"pace": @([CMPedometer isPaceAvailable]),
              @"cadence": @([CMPedometer isCadenceAvailable]),
             @"distance": @([CMPedometer isDistanceAvailable]),
           @"floorCount": @([CMPedometer isFloorCountingAvailable]),
    });
}

RCT_EXPORT_METHOD(queryStepCounterDataBetweenDates:(NSDate *)startDate
                                           endDate:(NSDate *)endDate
                                           handler:(RCTResponseSenderBlock)handler) {
    [self.pedometer queryPedometerDataFromDate:startDate
                                        toDate:endDate
      withHandler:^(CMPedometerData *pedometerData, NSError *error) {
          handler(@[error.description?:[NSNull null],
                   [self dictionaryFromPedometerData:pedometerData]]);
      }];
}

RCT_EXPORT_METHOD(startStepCounterUpdate:(NSDate *)date) {
    [self.pedometer startPedometerUpdatesFromDate:date?:[NSDate date]
                                      withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        if(error) {
            [self sendEventWithName:@"StepCounter.errorOccurred"
                               body:error];
        } else if (pedometerData) {
            [self sendEventWithName:@"StepCounter.stepCounterUpdate"
             body:[self dictionaryFromPedometerData:pedometerData]];
        }
    }];
}

- (NSDictionary *)dictionaryFromPedometerData:(CMPedometerData *)data {
    NSNumber *startDate = @((long long)(data.startDate.timeIntervalSince1970 * 1000.0));
    NSNumber *endDate = @((long long)(data.endDate.timeIntervalSince1970 * 1000.0));
    return @{
        @"counterType": @"CMPedometer",
          @"startDate": startDate?:[NSNull null],
            @"endDate": endDate?:[NSNull null],
              @"steps": data.numberOfSteps?:[NSNull null],
           @"distance": data.distance?:[NSNull null],
     @"floorsAscended": data.floorsAscended?:[NSNull null],
    @"floorsDescended": data.floorsDescended?:[NSNull null],
    };
}

RCT_EXPORT_METHOD(stopStepCounterUpdate) {
    [self.pedometer stopPedometerUpdates];
    [[SOMotionDetecter sharedInstance] stopDetection];
}

RCT_EXPORT_METHOD(startStepsDetection) {
    [[SOMotionDetecter sharedInstance]
      startDetectionWithUpdateBlock:^(NSError *error) {
        if(error) {
            [self sendEventWithName:@"StepCounter.errorOccurred"
                               body:error];
        } else {
            [self sendEventWithName:@"StepCounter.stepDetected"
                               body:@true];
        }
    }];
}

- (BOOL)authorizationStatus {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    CMAuthorizationStatus status = [CMPedometer authorizationStatus];
    return status == CMAuthorizationStatusAuthorized;
#pragma clang diagnostic pop
#endif
}

#pragma mark - Private

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    _pedometer = [[CMPedometer alloc]init];
    return self;
}

@end