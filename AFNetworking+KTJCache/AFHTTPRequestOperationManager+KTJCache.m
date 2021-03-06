//
//  AFHTTPRequestOperationManager+KTJCache.m
//  Demo - AFNetworking+KTJCache
//
//  Created by 孙继刚 on 15/8/12.
//  Copyright (c) 2015年 Madordie. All rights reserved.
//

#import "AFHTTPRequestOperationManager+KTJCache.h"
#import "EGOCache.h"
#import <objc/runtime.h>

#ifndef KTJChangeIMP
#define KTJChangeIMP(JOriginalSEL, JSwizzledSEL)  \
    {   \
        Class class = [self class]; \
        SEL originalSelector = (JOriginalSEL);  \
        SEL swizzledSelector = (JSwizzledSEL);  \
        Method originalMethod = class_getInstanceMethod(class, originalSelector);   \
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);   \
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)); \
        if (didAddMethod){  \
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod)); \
        } else {    \
            method_exchangeImplementations(originalMethod, swizzledMethod); \
        }   \
    }
#endif


@interface AFHTTPRequestOperation (KTJCacheKey)

@property (nonatomic, copy) NSString *ktj_cacheKey;
- (void)ktj_saveIsCacheData:(BOOL)isCacheData;

@end

@implementation AFHTTPRequestOperation (KTJCacheKey)

- (void)ktj_saveIsCacheData:(BOOL)isCacheData {
    objc_setAssociatedObject(self, @selector(ktj_isCacheData), @(isCacheData), OBJC_ASSOCIATION_RETAIN);
}
- (void)setKtj_cacheKey:(NSString *)key {
    objc_setAssociatedObject(self, @selector(ktj_cacheKey), key, OBJC_ASSOCIATION_COPY);
}
- (NSString *)ktj_cacheKey {
    return objc_getAssociatedObject(self, @selector(ktj_cacheKey));
}
@end

@implementation AFHTTPRequestOperation (KTJCache)

- (BOOL)ktj_isCacheData {
    return [objc_getAssociatedObject(self, @selector(ktj_isCacheData)) boolValue];
}

- (void)setKtj_needResetCache:(BOOL)ktj_needResetCache {
    objc_setAssociatedObject(self, @selector(ktj_needResetCache), @(ktj_needResetCache), OBJC_ASSOCIATION_RETAIN);
}
- (BOOL)ktj_needResetCache {
    return [objc_getAssociatedObject(self, @selector(ktj_needResetCache)) boolValue];
}
- (NSString *)ktj_operationCacheKey {
    return [self.ktj_cacheKey copy];
}

@end


#define KTJCacheKeyForEGO   @"KTJCacheKeyForEGO"
NSString* KTJ_MD5(NSString *str);
@implementation AFHTTPRequestOperationManager (KTJCache)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KTJChangeIMP(@selector(HTTPRequestOperationWithRequest:success:failure:), @selector(ktjhook_HTTPRequestOperationWithRequest:success:failure:));
        KTJChangeIMP(@selector(init), @selector(ktjhook_init));
        KTJChangeIMP(@selector(initWithBaseURL:), @selector(ktjhook_initinitWithBaseURL:));
    });
}
- (instancetype)ktjhook_init {
    id _self = [self ktjhook_init];
    self.ktj_cacheData = YES;
    self.ktj_cacheAddedKey = nil;
    self.ktj_cacheTimeoutInterval = CGFLOAT_MAX;
    return _self;
}
- (instancetype)ktjhook_initinitWithBaseURL:(NSURL *)url {
    id _self = [self ktjhook_initinitWithBaseURL:url];
    self.ktj_cacheData = YES;
    self.ktj_cacheAddedKey = nil;
    self.ktj_cacheTimeoutInterval = CGFLOAT_MAX;
    return _self;
}
- (AFHTTPRequestOperation *)ktjhook_HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    AFHTTPRequestOperation *operation = [self ktjhook_HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
        if (!operation.ktj_isCacheData && operation.ktj_needResetCache && operation.ktj_cacheKey) {
            [[AFHTTPRequestOperationManager ktj_EGOCache] setObject:responseObject forKey:operation.ktj_cacheKey withTimeoutInterval:self.ktj_cacheTimeoutInterval];
            operation.ktj_needResetCache = NO;
        }
    } failure:failure];
    
    //  缓存判断
    if (self.ktj_cacheData) {
        NSString *cacheKey;
        //  生成特定的KEY
        if ([request.HTTPMethod isEqualToString:@"GET"]) {
            cacheKey = KTJ_MD5([NSString stringWithFormat:@"KTJ%@+%@",
                                operation.request.HTTPMethod, operation.request.URL.absoluteString]);
        } else if (self.ktj_cacheAddedKey.length) {
            cacheKey = KTJ_MD5([NSString stringWithFormat:@"KTJ%@+%@+%@",
                                operation.request.HTTPMethod, operation.request.URL.absoluteString, self.ktj_cacheAddedKey]);
        }
        
        //  判断能否进行缓存。
        if (cacheKey) {
            //  这个请求进行缓存
            operation.ktj_cacheKey = cacheKey;
            id cacheData = [[AFHTTPRequestOperationManager ktj_EGOCache] objectForKey:cacheKey];
            if (cacheData && success) {
                [operation ktj_saveIsCacheData:YES];
                success(operation, cacheData);
            }
        }
    }
    
    self.ktj_cacheAddedKey = nil;
    self.ktj_cacheData = YES;
    [operation ktj_saveIsCacheData:NO];
    operation.ktj_needResetCache = YES;
    self.ktj_cacheTimeoutInterval = CGFLOAT_MAX;
    
    return operation;
}
+ (EGOCache *)ktj_EGOCache {
    static EGOCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[EGOCache alloc] init];
    });
    return cache;
}
- (BOOL)ktj_cacheData {
    return [objc_getAssociatedObject(self, @selector(ktj_cacheData)) boolValue];
}
- (void)setKtj_cacheData:(BOOL)ktj_cacheData {
    objc_setAssociatedObject(self, @selector(ktj_cacheData), @(ktj_cacheData), OBJC_ASSOCIATION_RETAIN);
}
- (NSString *)ktj_cacheAddedKey {
    return objc_getAssociatedObject(self, @selector(ktj_cacheAddedKey));
}
- (void)setKtj_cacheAddedKey:(NSString *)ktj_cacheAddedKey {
    objc_setAssociatedObject(self, @selector(ktj_cacheAddedKey), ktj_cacheAddedKey, OBJC_ASSOCIATION_COPY);
}
- (void)setKtj_cacheTimeoutInterval:(NSTimeInterval)ktj_cacheTimeoutInterval {
    objc_setAssociatedObject(self, @selector(ktj_cacheTimeoutInterval), @(ktj_cacheTimeoutInterval), OBJC_ASSOCIATION_RETAIN);
}
- (NSTimeInterval)ktj_cacheTimeoutInterval {
    return [objc_getAssociatedObject(self, @selector(ktj_cacheTimeoutInterval)) doubleValue];
}
@end

#import <CommonCrypto/CommonDigest.h>
NSString* KTJ_MD5(NSString *str) {
        //  防止发生碰撞，所以md5+sha1 -> key.
    const char *cStr = [str UTF8String];
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2 + CC_SHA1_DIGEST_LENGTH * 2];
    
    {
        // md5
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5( cStr, (unsigned int)strlen(cStr), digest );
        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [result appendFormat:@"%02x", digest[i]];
        }
    }
    
    {
        // sha1
        NSData *data = [NSData dataWithBytes:cStr length:str.length];
        
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];
        
        CC_SHA1(data.bytes, (unsigned int)data.length, digest);
        
        for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [result appendFormat:@"%02x", digest[i]];
        }
    }
    
    return result;
}