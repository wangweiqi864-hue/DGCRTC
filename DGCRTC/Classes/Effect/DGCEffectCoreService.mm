//
//  DGCEffectCoreService.m
//  DGCRTC
//
//  Created by admin on 2024/8/7.
//

#import "DGCEffectCoreService.h"
#import <EffectCore/BEAvatarManager.h>
#import <EffectCore/BEEffectResourceHelper.h>
#import "DGCBEGLUtils.h"


static NSRecursiveLock *dgc_sdkLock = nil;

@interface DGCEffectCoreService()<BEEffectManagerDelegate>{
    BOOL dgc_isInitOK; // 是否初始化成功
}
// {zh} / 特效 SDK {en} /Special effects SDK
@property (nonatomic, strong) BEEffectManager *dgc_manager;

@property (nonatomic, strong) BEImageUtils *dgc_imageUtils;

// {zh} / gl 上下文，可供 SDK 使用 {en} /Gl context, available for SDK
@property (nonatomic, strong) EAGLContext *dgc_glContext;
@property (nonatomic, strong) EAGLSharegroup *dgc_sharegroup;

@end

@implementation DGCEffectCoreService

+(instancetype)share{
    static dispatch_once_t dgc_onceToken;
    static DGCEffectCoreService *dgc_service;
    dispatch_once(&dgc_onceToken, ^{
        dgc_service = [DGCEffectCoreService new];
    });
    return dgc_service;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isCanUse = false;
        dgc_isInitOK = false;
    }
    return self;
}

+(void)initServer{
    [[DGCEffectCoreService share] dgc_initServer];
}

-(void)dgc_initServer{
    _isCanUse = true;
    dgc_isInitOK = false;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dgc_initSDK];
    });
}

- (int)dgc_initSDK {
    self.dgc_sharegroup = [[EAGLSharegroup alloc] init];
    if (self.dgc_glContext == nil) {
        self.dgc_glContext = [DGCBEGLUtils createContextWithDefaultAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:self.dgc_sharegroup];
    }
    
    if ([EAGLContext currentContext] != self.dgc_glContext) {
        [EAGLContext setCurrentContext:self.dgc_glContext];
    }
    
    static dispatch_once_t dgc_onceToken;
    dispatch_once(&dgc_onceToken, ^{
        dgc_sdkLock = [[NSRecursiveLock alloc] init];
    });
    
    self.dgc_imageUtils = [[BEImageUtils alloc] init];
    
    self.dgc_manager = [[BEEffectManager alloc] initWithResourceProvider:[BEEffectResourceHelper new] licenseProvider:[BELicenseHelper shareInstance]];
    int dgc_ret = [self.dgc_manager initTask];
    if (dgc_ret == BEF_RESULT_SUC || dgc_ret == BEF_RESULT_SUC)
    {
        NSLog(@"DGCEffectCoreService--初始化成功");
        dgc_isInitOK = true;
        [self dgc_loadData];
    }else{
        NSLog(@"DGCEffectCoreService--初始化失败..");
    }
    self.dgc_manager.delegate = self;
    return dgc_ret;
}


-(void)dgc_loadData{
    
    
}

- (void)updateComposerNode:(NSArray<DGCRTCEffectItem *> *)items{
    if (dgc_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSMutableArray<NSString *> *dgc_nodes = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableArray<NSString *> *dgc_tags = [NSMutableArray arrayWithCapacity:items.count];
    for (DGCRTCEffectItem *dgc_item in items) {
        if (![dgc_nodes containsObject:dgc_item.path]) {
            if (dgc_item.path.length > 0) {
                [dgc_nodes addObject:dgc_item.path];
                [dgc_tags addObject:dgc_item.tag == nil ? @"" : dgc_item.tag];
            }
        }
    }
    
    NSMutableArray *dgc_itemsArray = [self dgc_arrayIndex:dgc_nodes];
//    [self.videoSource pause];
    [self dgc_lockSDK];
    [self.dgc_manager updateComposerNodes:dgc_itemsArray withTags:dgc_tags];
    [self dgc_unlockSDK];
//    [self.videoSource resume];
    
}

- (void)updateComposerNodeIntensity:(DGCRTCEffectItem *)dgc_item value: (float)value {
    if (dgc_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
//    [self.allIntensityItem addObject:dgc_item];
//    [self.videoSource pause];
    NSLog(@"DGCEffectCoreService--updateComposerNodeIntensity--path=%@--key=%@-value=%f",dgc_item.path,dgc_item.key,value);
    [self dgc_lockSDK];
    [self.dgc_manager updateComposerNodeIntensity:dgc_item.path key:dgc_item.key intensity:value];
    [self dgc_unlockSDK];
//    [self.videoSource resume];
}


- (void)updateComposerNodeIntensity:(NSString *)key path:(NSString *)path value: (float)value {
    if (dgc_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSLog(@"DGCEffectCoreService--updateComposerNodeIntensity--path=%@--key=%@-value=%f",path,key,value);
    [self dgc_lockSDK];
    [self.dgc_manager updateComposerNodeIntensity:path key:key intensity:value];
    [self dgc_unlockSDK];
}


// 滤镜
- (void)updateFilterNodeIntensity:(DGCRTCEffectItem *)dgc_item value:(float)value {
    if (dgc_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSLog(@"DGCEffectCoreService--updateFilterNodeIntensity--path=%@--key=%@-value=%f",dgc_item.filterPath,dgc_item.key,value);
    [self dgc_lockSDK];
    [self.dgc_manager setFilterPath:dgc_item.filterPath];
    [self.dgc_manager setFilterIntensity:value];
    [self dgc_unlockSDK];
}

#pragma mark BEEffectManagerDelegate
- (BOOL)msgProc:(unsigned int)unMsgID arg1:(int)nArg1 arg2:(int)nArg2 arg3:(const char *)cArg3 {
    if(unMsgID == 0x100)
    {
        NSLog(@"be_effect--该设备不支持");
    }
    return NO;
    
}

//beauty_IOS_lite


- (NSMutableArray *)dgc_arrayIndex:(NSMutableArray<NSString *> *)items {
    NSMutableArray *dgc_itemsArray = [NSMutableArray arrayWithArray:items];
    NSMutableArray *dgc_qualityArray = [[NSMutableArray alloc] init];
    NSArray *dgc_idsArray = @[@"/palette/color", @"/palette/contrast", @"/palette/light",  @"/palette/vignette", @"/palette/particle"];
    for (int dgc_i = 0; dgc_i < items.count; dgc_i++) {
        NSString *dgc_obj = items[dgc_i];
        for (int dgc_j = 0; dgc_j < dgc_idsArray.count; dgc_j++) {
            if ([dgc_obj isEqualToString:dgc_idsArray[dgc_j]]) {
                [dgc_qualityArray addObject:dgc_obj];
                [dgc_itemsArray removeObject:dgc_obj];
            }
        }
    }
    NSMutableArray *dgc_itemsEndArray = [[NSMutableArray alloc] init];
    for (int dgc_j = 0; dgc_j < dgc_idsArray.count; dgc_j++) {
        for (int dgc_i = 0; dgc_i < dgc_qualityArray.count; dgc_i++) {
            if (dgc_idsArray[dgc_j] == dgc_qualityArray[dgc_i]) {
                [dgc_itemsEndArray addObject:dgc_qualityArray[dgc_i]];
            }
        }
    }
    [dgc_itemsArray addObjectsFromArray:dgc_itemsEndArray];
    return dgc_itemsArray;
}

- (void)dgc_lockSDK {
    [dgc_sdkLock lock];
}

- (void)dgc_unlockSDK {
    [dgc_sdkLock unlock];
}


- (CVPixelBufferRef)processWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(int)rotation timeStamp:(double)timeStamp {
    if (dgc_isInitOK == false) { // 未初始化
//        NSLog(@"DGCEffectCoreService--初始化失败..");
        return pixelBuffer;
    }
    
    if ([EAGLContext currentContext] != self.dgc_glContext) {
        [EAGLContext setCurrentContext:self.dgc_glContext];
    }
//    double originTimestamp = timeStamp; // {zh} originTimestamp仅用于本地写入视频，其他依然使用timeStamp {en} originTimestamp is only used to write video, others still use timeStamp
//    if (self.videoSourceConfig.type == BEVideoSourceVideo) {
//        // {zh} 本地导入视频时，时间戳是从0开始，但是effect内部加了时间戳判断保护，会导致报错，上层兼容下 {en} if source is local video, timestamp start at 0 and the first frame is repeated three times, which conflicts with the protection inside Effect-SDK
//        timeStamp = [[NSDate date] timeIntervalSince1970];
//    }

    BEPixelBufferInfo *dgc_pixelBufferInfo = [self.dgc_imageUtils getCVPixelBufferInfo:pixelBuffer];
    if (dgc_pixelBufferInfo.format != BE_BGRA) {
        pixelBuffer = [self.dgc_imageUtils transforCVPixelBufferToCVPixelBuffer:pixelBuffer outputFormat:BE_BGRA];
    }
    
    if (rotation != 0) {
        //  {zh} 特效 SDK 接收的纹理必须是正的，所以在调用 SDK 之前，需要先行旋转一下  {en} The dgc_texture received by the special effects SDK must be positive, so before calling the SDK, you need to rotate it first
        pixelBuffer = [self.dgc_imageUtils rotateCVPixelBuffer:pixelBuffer rotation:rotation];
    }
    id<BEGLTexture> dgc_texture = [self.dgc_imageUtils transforCVPixelBufferToTexture:pixelBuffer];
    BEPixelBufferGLTexture *dgc_outTexture = nil;

    dgc_outTexture = [self.dgc_imageUtils getOutputPixelBufferGLTextureWithWidth:dgc_texture.width height:dgc_texture.height format:BE_BGRA withPipeline:self.dgc_manager.usePipeline];
    
//    self.dgc_manager.frontCamera = self.videoSource.frontCamera;
    int dgc_ret = [self.dgc_manager processTexture:dgc_texture.texture outputTexture:dgc_outTexture.texture width:dgc_texture.width height:dgc_texture.height rotate:[self dgc_getDeviceOrientation] timeStamp:timeStamp];
    if (dgc_ret != BEF_RESULT_SUC) {
        dgc_outTexture = dgc_texture;
    }
    CVPixelBufferRef dgc_outputPixelBuffer = dgc_outTexture.pixelBuffer;
    
    return dgc_outputPixelBuffer;
    
//    [self drawGLTextureOnScreen:dgc_outTexture rotation:0];
    
//    if (rotation != 0) {
//        CVPixelBufferRelease(pixelBuffer);
//    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[BEPreviewSizeManager singletonInstance] updateViewWidth:self.view.frame.size.width viewHeight:self.view.frame.size.height previewWidth:dgc_outTexture.width previewHeight:dgc_outTexture.height fitCenter:self.videoSourceConfig.type != BEVideoSourceCamera];
//    });
}


- (bef_ai_rotate_type)dgc_getDeviceOrientation {
    return BEF_AI_CLOCKWISE_ROTATE_0;
//    if (self.videoSourceConfig.type != BEVideoSourceCamera) {
//        return BEF_AI_CLOCKWISE_ROTATE_0;
//    }
//    UIDeviceOrientation orientation = [self.orientationDetector getDeviceOrientation];
//    switch (orientation) {
//        case UIDeviceOrientationPortrait:
//            return BEF_AI_CLOCKWISE_ROTATE_0;
//
//        case UIDeviceOrientationPortraitUpsideDown:
//            return BEF_AI_CLOCKWISE_ROTATE_180;
//
//        case UIDeviceOrientationLandscapeLeft:
//            return BEF_AI_CLOCKWISE_ROTATE_270;
//
//        case UIDeviceOrientationLandscapeRight:
//            return BEF_AI_CLOCKWISE_ROTATE_90;
//
//        default:
//            return BEF_AI_CLOCKWISE_ROTATE_0;
//    }
}

//- (void)drawGLTextureOnScreen:(id<BEGLTexture>)dgc_texture rotation:(int)rotation {
//    [self.glView renderWithTexture:dgc_texture.dgc_texture size:CGSizeMake(dgc_texture.width, dgc_texture.height) applyingOrientation:rotation fitType:[self be_fitCenterDraw] ? 1 : 0];
//}

@end
