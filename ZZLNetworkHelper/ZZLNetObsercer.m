//
//  ZZLNetObsercer.m
//  ZZLNetworkHelper
//
//  Created by lei on 16/9/24.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ZZLNetObsercer.h"
#import "Reachability.h"
#import "SimplePinger.h"

NSString *ZZLReachabilityChangedNotification = @"ZZLNetworkReachabilityChangedNotification";

@interface ZZLNetObsercer()

@property (nonatomic,copy) NSString *host;

@property (nonatomic,strong) Reachability *hostReachability;

@property (nonatomic,strong) SimplePinger *pinger;
@end

@implementation ZZLNetObsercer
#pragma mark - 初始化
+ (instancetype)defultObsever{
    ZZLNetObsercer *obsever = [[self alloc] init];
    obsever.host = @"www.baidu.com";
    return obsever;
}

+ (instancetype)observerWithHost:(NSString *)host{
    ZZLNetObsercer *obsever = [[self alloc] init];
    obsever.host = host;
    return obsever;
}

- (instancetype)init{
    if (self = [super init]) {
        _networkStatus = -1;
        _failureTimes = 2;
        _interval = 1.0;
    }
    return self;
}

- (void)dealloc{
    [self.hostReachability stopNotifier];
    [self.pinger stopNotifier];
}
#pragma mark - function

- (void)startNotifier{
    [self.hostReachability startNotifier];
    [self.pinger startNotifier];
}

- (void)stopNotifier{
    [self.hostReachability startNotifier];
    [self.pinger startNotifier];
}

#pragma mark - delegate
- (void)networkStatusDidChanged{
    
    //获取两种方法得到的联网状态,并转为BOOL值
    BOOL status1 = [self.hostReachability currentReachabilityStatus];
    
    BOOL status2 =  self.pinger.reachable;
    
    //综合判断网络,判断原则:Reachability -> pinger
    if (status1 && status2) {//有网
        self.networkStatus = self.netWorkDetailStatus;
    }else{//无网
        self.networkStatus = ZZLNetworkStatusNone;
    }
}

#pragma mark - setter
- (void)setNetworkStatus:(ZZLNetworkStatus)networkStatus{
    if (_networkStatus != networkStatus) {
        _networkStatus = networkStatus;
        
        NSLog(@"网络状态-----%@",self.networkDict[@(networkStatus)]);
        
        //有代理
        if(self.delegate){//调用代理
            if ([self.delegate respondsToSelector:@selector(observer:host:networkStatusDidChanged:)]) {
                [self.delegate observer:self host:self.host networkStatusDidChanged:networkStatus];
            }
        }else{//发送全局通知
            NSDictionary *info = @{@"status" : @(networkStatus),
                                   @"host"   : self.host      };
            [[NSNotificationCenter defaultCenter] postNotificationName:ZZLReachabilityChangedNotification object:nil userInfo:info];
        }
    }
    
}
#pragma mark - getter

- (Reachability *)hostReachability{
    if (_hostReachability == nil) {
        _hostReachability = [Reachability reachabilityWithHostName:self.host];
        
        __weak typeof(self) weakSelf = self;
        [_hostReachability setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _hostReachability;
}

- (SimplePinger *)pinger{
    if (_pinger == nil) {
        _pinger = [SimplePinger simplePingerWithHostName:self.host];
        _pinger.supportIPv4 = self.supportIPv4;
        _pinger.supportIPv6 = self.supportIPv6;
        _pinger.interval = self.interval;
        _pinger.failureTimes = self.failureTimes;
        
        __weak typeof(self) weakSelf = self;
        [_pinger setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _pinger;
}
#pragma mark - tools
- (ZZLNetworkStatus)netWorkDetailStatus{
    UIApplication *app = [UIApplication sharedApplication];
    UIView *statusBar = [app valueForKeyPath:@"statusBar"];
    UIView *foregroundView = [statusBar valueForKeyPath:@"foregroundView"];
    
    UIView *networkView = nil;
    
    for (UIView *childView in foregroundView.subviews) {
        if ([childView isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            networkView = childView;
        }
    }
    
    ZZLNetworkStatus status = ZZLNetworkStatusNone;
    
    if (networkView) {
        int netType = [[networkView valueForKeyPath:@"dataNetworkType"]intValue];
        switch (netType) {
            case 0:
                status = ZZLNetworkStatusNone;
                break;
            case 1://实际上是2G
                status = ZZLNetworkStatusUkonow;
                break;
            case 2:
                status = ZZLNetworkStatus3G;
                break;
            case 3:
                status = ZZLNetworkStatus4G;
                break;
            case 5:
                status = ZZLNetworkStatusWifi;
                break;
            default:
                status = ZZLNetworkStatusUkonow;
                break;
        }
    }
    return status;
}

- (NSDictionary *)networkDict{
    return @{
             @(ZZLNetworkStatusNone)   : @"无网络",
             @(ZZLNetworkStatusUkonow) : @"未知网络",
             @(ZZLNetworkStatus3G)     : @"3G网络",
             @(ZZLNetworkStatus4G)     : @"4G网络",
             @(ZZLNetworkStatusWifi)   : @"WIFI网络",
             };
}
@end

