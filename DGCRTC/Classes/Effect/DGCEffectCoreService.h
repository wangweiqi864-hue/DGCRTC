//
//  DGCEffectCoreService.h
//  DGCRTC
//
//  Created by admin on 2024/8/7.
//

#import <Foundation/Foundation.h>
#import "DGCRTCEffectItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DGCEffectCoreService : NSObject

/// 是否可用
@property(assign,nonatomic,readonly) BOOL isCanUse;

+(instancetype)share;

-(instancetype)init NS_UNAVAILABLE;

+(void)initServer;

//- (int)initSDK;

- (void)updateComposerNode:(NSArray<DGCRTCEffectItem *> *)items;

- (void)updateComposerNodeIntensity:(DGCRTCEffectItem *)item value : (float) value;
// 直接给到底层使用的key和path参数
- (void)updateComposerNodeIntensity:(NSString *)key path:(NSString *)path value: (float)value;
// 滤镜
- (void)updateFilterNodeIntensity:(DGCRTCEffectItem *)item value:(float)value;

- (CVPixelBufferRef)processWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(int)rotation timeStamp:(double)timeStamp;

@end

NS_ASSUME_NONNULL_END
