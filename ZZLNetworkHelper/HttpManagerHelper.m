//
//  HttpManagerHelper.m
//  ZZLNetworkHelper
//
//  Created by lei on 16/9/24.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "HttpManagerHelper.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#ifdef DEBUG
#define HttpLog(...) NSLog(@"%s 第%d行 \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define HttpLog(...)
#endif


@implementation HttpManagerHelper

static BOOL _isNetwork;
static AFHTTPSessionManager *_manager;
static HttpManagerHelper *manager = nil;
+(instancetype)sharedNetManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HttpManagerHelper alloc] init];
        
    });
    return manager;
}

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(NetworkStatus)networkStatus
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status)
            {
                case AFNetworkReachabilityStatusUnknown:
                    networkStatus ? networkStatus(HttpNetworkStatusUnknown) : nil;
                    _isNetwork = NO;
                    HttpLog(@"未知网络");
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    networkStatus ? networkStatus(HttpNetworkStatusNotReachable) : nil;
                    _isNetwork = NO;
                    HttpLog(@"无网络");
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    networkStatus ? networkStatus(HttpNetworkStatusReachableViaWWAN) : nil;
                    _isNetwork = YES;
                    HttpLog(@"手机自带网络");
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    networkStatus ? networkStatus(HttpNetworkStatusReachableViaWiFi) : nil;
                    _isNetwork = YES;
                    HttpLog(@"WIFI");
                    break;
            }
        }];
        
        [manager startMonitoring];
    });
}

+ (BOOL)currentNetworkStatus
{
    return _isNetwork;
}

#pragma mark - GET请求无缓存

- (void)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure
{
     [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}


#pragma mark - POST请求无缓存

- (void)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure
{
     [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}


#pragma mark - GET请求自动缓存

- (void)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
            responseCache:(HttpRequestCache)responseCache
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure
{
    //读取缓存
    responseCache ? responseCache([HttpNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
     [_manager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        //对数据进行异步缓存
        responseCache ? [HttpNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        
        HttpLog(@"responseObject = %@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
        HttpLog(@"error = %@",error);
        
    }];
}


#pragma mark - POST请求自动缓存

- (void)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
             responseCache:(HttpRequestCache)responseCache
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure
{
    //读取缓存
    responseCache ? responseCache([HttpNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    
     [_manager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        //对数据进行异步缓存
        responseCache ? [HttpNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        
        HttpLog(@"responseObject = %@",responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
        HttpLog(@"error = %@",error);
    }];
    
}

#pragma mark - 上传图片文件

- (void)uploadWithImage:(NSString *)URL
             parameters:(NSDictionary *)parameters
                 images:(NSArray<UIImage *> *)images
                   name:(NSString *)name
               progress:(HttpProgress)progress
                success:(HttpRequestSuccess)success
                failure:(HttpRequestFailed)failure
{
    
     [_manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //压缩-添加-上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            // 设置时间格式
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"%@%d.jpg",str,((arc4random() % 501) + 500)];
          
            //压缩图片

            NSData *imgData = UIImageJPEGRepresentation(image, 0.7);
            //拼接data
            if (imgData != nil) {
                [formData appendPartWithFileData:imgData name:@"pic[]" fileName:fileName mimeType:@"image/*"];
            }

        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        HttpLog(@"responseObject = %@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
        HttpLog(@"error = %@",error);
    }];
}

#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(HttpProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(HttpRequestFailed)failure
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [_manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        progress ? progress(downloadProgress) : nil;
        HttpLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        HttpLog(@"downloadDir = %@",downloadDir);
        
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if(failure && error) {failure(error) ; return ;};
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
        
    }];
    
    //开始下载
    [downloadTask resume];
    
    return downloadTask;
    
}


#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager,
 *  + (void)initialize该初始化方法在当用到此类时候只调用一次
 */
+ (void)initialize
{
    _manager = [AFHTTPSessionManager manager];
    //设置请求参数的类型:JSON (AFJSONRequestSerializer,AFHTTPRequestSerializer)
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置请求的超时时间
    _manager.requestSerializer.timeoutInterval = 30.f;
    //设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    //打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 重置AFHTTPSessionManager相关属性
+ (void)setRequestSerializer:(HttpRequestSerializer)requestSerializer
{
    _manager.requestSerializer = requestSerializer==HttpRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : nil ;
}

+ (void)setResponseSerializer:(HttpResponseSerializer)responseSerializer
{
    _manager.responseSerializer = responseSerializer==HttpResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : nil;
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    _manager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [_manager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open
{
    !open ? [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO] : nil ;
}


@end
