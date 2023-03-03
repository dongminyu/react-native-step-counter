#import "RNStepCounter.h"

#import <CoreMotion/CMPedometer.h>

@implementation RNStepCounter
RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents {
    return @[@"StepCounter.stepCounterUpdate"];
}

RCT_EXPORT_METHOD(isStepCountingSupported:(RCTPromiseResolveBlock)resolve
                                   reject:(RCTPromiseRejectBlock)reject) {
    resolve(@[[NSNull null],
               [self dictionaryStepCounterStatus]]);
}

- (void)queryStepCounterDataBetweenDates:(NSDate *)startDate
                                 endDate:(NSDate *)endDate
                                 handler:(RCTResponseSenderBlock)callback {
    [self.pedometer queryPedometerDataFromDate:startDate
                                        toDate:endDate
                                   withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        callback(@[error.description?:[NSNull null],
                  [self dictionaryFromPedometerData:pedometerData]]);
    }];
}

RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSNumber *, 
                           startStepCounterUpdate:(double)date) {
    [self.pedometer startPedometerUpdatesFromDate:[[NSDate date]init]
                                      withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        if (pedometerData) {
            [self sendEventWithName:@"StepCounter.stepCounterUpdate"
           body:[self dictionaryFromPedometerData:pedometerData]];
        }
    }];
    return @(1);
}

- (NSDictionary *)dictionaryStepCounterStatus {
    return @{
        @"granted": @([CMPedometer authorizationStatus]),
        @"supported": @([CMPedometer isStepCountingAvailable])
    };
}

- (NSDictionary *)dictionaryFromPedometerData:(CMPedometerData *)data {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    });
    return @{
        @"startDate": [formatter stringFromDate:data.startDate]?:[NSNull null],
        @"endDate": [formatter stringFromDate:data.endDate]?:[NSNull null],
        @"steps": data.numberOfSteps?:[NSNull null],
        @"distance": data.distance?:[NSNull null],
        @"dailyGoal": @(10000),
        @"counterType": @"CMPedometer",
        @"floorsAscended": data.floorsAscended?:[NSNull null],
        @"floorsDescended": data.floorsDescended?:[NSNull null],
    };
}

RCT_EXPORT_METHOD(stopStepCounterUpdate) {
    [self.pedometer stopPedometerUpdates];
}

- (bool)authorizationStatus {
    NSString *response = @"not_available";
    bool isGranted = false;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    CMAuthorizationStatus status = [CMPedometer authorizationStatus];
    switch (status) {
        case CMAuthorizationStatusAuthorized:
            response = @"authorized";
            isGranted = true;
            break;
        default:
            break;
    }
    return isGranted;
#pragma clang diagnostic pop
#endif
}

#pragma mark - Private

-(void)addListener:(NSString *)eventName {
    // NOTHING
}

-(void)removeListeners:(double)count {
    // NOTHING
}

-(CMPedometer *)pedometer {
    return [[CMPedometer alloc]init];
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeStepCounterSpecJSI>(params);
}
#endif

@end
