//
//  NSTimer+Kit.h
//  ZDSApp
//
//  Created by lei on 2016/9/27.
//  Copyright © 2016年 lei. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^TimerCallBack)(NSTimer *timer);
@interface NSTimer (Kit)
/**
 *  @author lei, 16-08-17 10:08:56
 *
 *  倒计时
 */
+(NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                     count:(NSInteger)count
                                  callback:(TimerCallBack)callback;


@end
