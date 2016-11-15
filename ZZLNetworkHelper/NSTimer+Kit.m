//
//  NSTimer+Kit.m
//  ZDSApp
//
//  Created by lei on 2016/9/27.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "NSTimer+Kit.h"
#import <objc/runtime.h>

static const void *s_private_currentCountTime = "s_private_currentCountTime";

@implementation NSTimer (Kit)

- (NSNumber *)private_currentCountTime {
    NSNumber *obj = objc_getAssociatedObject(self, s_private_currentCountTime);
    
    if (obj == nil) {
        obj = @(0);
        
        [self setprivate_currentCountTime:obj];
    }
    
    return obj;
}

- (void)setprivate_currentCountTime:(NSNumber *)time {
    objc_setAssociatedObject(self,
                             s_private_currentCountTime,
                             time, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                          count:(NSInteger)count
                                       callback:(TimerCallBack)callback {
    if (count <= 0) {
        return [self scheduledTimerWithTimeInterval:interval
                                                repeats:YES
                                               callback:callback];
    }
    
    NSDictionary *userInfo = @{@"callback"     : callback,
                               @"count"        : @(count)};
    return [NSTimer scheduledTimerWithTimeInterval:interval
                                            target:self
                                          selector:@selector(onTimerUpdateCountBlock:)
                                          userInfo:userInfo
                                           repeats:YES];
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        repeats:(BOOL)repeats
                                       callback:(TimerCallBack)callback {
    return [NSTimer scheduledTimerWithTimeInterval:interval
                                            target:self
                                          selector:@selector(onTimerUpdateBlock:)
                                          userInfo:callback
                                           repeats:repeats];
}

- (void)fireTimer {
    [self setFireDate:[NSDate distantPast]];
}

- (void)unfireTimer {
    [self setFireDate:[NSDate distantFuture]];
}

- (void)sinvalidate {
    if (self.isValid) {
        [self invalidate];
    }
}

#pragma mark - Private
+ (void)onTimerUpdateBlock:(NSTimer *)timer {
    TimerCallBack block = timer.userInfo;
    
    if (block) {
        block(timer);
    }
}

+ (void)onTimerUpdateCountBlock:(NSTimer *)timer {
    NSInteger currentCount = [[timer private_currentCountTime] integerValue];
    
    NSDictionary *userInfo = timer.userInfo;
    TimerCallBack callback = userInfo[@"callback"];
    NSNumber *count = userInfo[@"count"];
    
    if (currentCount < count.integerValue) {
        currentCount++;
        [timer setprivate_currentCountTime:@(currentCount)];
        
        if (callback) {
            callback(timer);
        }
    } else {
        currentCount = 0;
        [timer setprivate_currentCountTime:@(currentCount)];
        
        [timer unfireTimer];
        [timer sinvalidate];
    }
}


@end
