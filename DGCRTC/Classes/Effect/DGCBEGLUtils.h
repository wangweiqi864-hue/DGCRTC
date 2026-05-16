//  DGCBEGLUtils.h
// EffectsARSDK


#ifndef BEGLUtils_h
#define BEGLUtils_h

#import <OpenGLES/EAGL.h>

@interface DGCBEGLUtils : NSObject

+ (EAGLContext *)createContextWithDefaultAPI:(EAGLRenderingAPI)api;

+ (EAGLContext *)createContextWithDefaultAPI:(EAGLRenderingAPI)api sharegroup:(EAGLSharegroup *)sharegroup;

@end


#endif /* BEGLUtils_h */
