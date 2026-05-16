//  DGCBEGLUtils.m
// EffectsARSDK


#import "DGCBEGLUtils.h"

@implementation DGCBEGLUtils

+ (EAGLContext *)createContextWithDefaultAPI:(EAGLRenderingAPI)api {
    while (api != 0) {
        EAGLContext *dgc_context = [[EAGLContext alloc] initWithAPI:api];
        if (dgc_context != nil) {
            return dgc_context;
        }
        NSLog(@"not support api %lu, use lower api %lu", (unsigned long)api, [self dgc_lowerAPI:api]);
        api = [self dgc_lowerAPI:api];
    }
    return nil;
}

+ (EAGLContext *)createContextWithDefaultAPI:(EAGLRenderingAPI)api sharegroup:(EAGLSharegroup *)sharegroup {
    while (api != 0) {
        EAGLContext *dgc_context = [[EAGLContext alloc] initWithAPI:api sharegroup:sharegroup];
        if (dgc_context != nil) {
            return dgc_context;
        }
        NSLog(@"not support api %lu, use lower api %lu", (unsigned long)api, [self dgc_lowerAPI:api]);
        api = [self dgc_lowerAPI:api];
    }
    return nil;
}

+ (EAGLRenderingAPI)dgc_lowerAPI:(EAGLRenderingAPI)api {
    switch (api) {
        case kEAGLRenderingAPIOpenGLES3:
            return kEAGLRenderingAPIOpenGLES2;
        case kEAGLRenderingAPIOpenGLES2:
            return kEAGLRenderingAPIOpenGLES1;
        case kEAGLRenderingAPIOpenGLES1:
            return 0;
    }
    return 0;
}

@end
