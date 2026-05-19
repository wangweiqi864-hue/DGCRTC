//
//  DGCEffectCoreService.m
//  DGCRTC
//
//  Created by admin on 2024/8/7.
//

#import "DGCEffectCoreService.h"
#import <EffectCore/DGCBEAvatarManager.h>
#import <EffectCore/DGCBEEffectResourceHelper.h>
#import "DGCBEGLUtils.h"


static NSRecursiveLock *SDK_LOCK = nil;

@interface DGCEffectCoreService()<BEEffectManagerDelegate>{
    BOOL _isInitOK; // 是否初始化成功
}
// {zh} / 特效 SDK {en} /Special effects SDK
@property (nonatomic, strong) DGCBEEffectManager *manager;

@property (nonatomic, strong) DGCBEImageUtils *imageUtils;

// {zh} / gl 上下文，可供 SDK 使用 {en} /Gl context, available for SDK
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) EAGLSharegroup *sharegroup;

@end

@implementation DGCEffectCoreService

+(instancetype)share{
    static dispatch_once_t onceToken;
    static DGCEffectCoreService *service;
    dispatch_once(&onceToken, ^{
        service = [DGCEffectCoreService new];
    });
    return service;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isCanUse = false;
        _isInitOK = false;
    }
    return self;
}

+(void)initServer{
    [[DGCEffectCoreService share] initServer];
}

-(void)initServer{
    _isCanUse = true;
    _isInitOK = false;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
    });
}

- (int)initSDK {
    self.sharegroup = [[EAGLSharegroup alloc] init];
    if (self.glContext == nil) {
        self.glContext = [DGCBEGLUtils createContextWithDefaultAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:self.sharegroup];
    }
    
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SDK_LOCK = [[NSRecursiveLock alloc] init];
    });
    
    self.imageUtils = [[DGCBEImageUtils alloc] init];
    
    self.manager = [[DGCBEEffectManager alloc] initWithResourceProvider:[DGCBEEffectResourceHelper new] licenseProvider:[DGCBELicenseHelper shareInstance]];
    int ret = [self.manager initTask];
    if (ret == BEF_RESULT_SUC || ret == BEF_RESULT_SUC)
    {
        NSLog(@"DGCEffectCoreService--初始化成功");
        _isInitOK = true;
        [self loadData];
    }else{
        NSLog(@"DGCEffectCoreService--初始化失败..");
    }
    self.manager.delegate = self;
    return ret;
}


-(void)loadData{
    
    
}

- (void)updateComposerNode:(NSArray<DGCRTCEffectItem *> *)items{
    if (_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSMutableArray<NSString *> *nodes = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableArray<NSString *> *tags = [NSMutableArray arrayWithCapacity:items.count];
    for (DGCRTCEffectItem *item in items) {
        if (![nodes containsObject:item.path]) {
            if (item.path.length > 0) {
                [nodes addObject:item.path];
                [tags addObject:item.tag == nil ? @"" : item.tag];
            }
        }
    }
    
    NSMutableArray *itemsArray = [self arrayIndex:nodes];
//    [self.videoSource pause];
    [self lockSDK];
    [self.manager updateComposerNodes:itemsArray withTags:tags];
    [self unlockSDK];
//    [self.videoSource resume];
    
}

- (void)updateComposerNodeIntensity:(DGCRTCEffectItem *)item value: (float)value {
    if (_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
//    [self.allIntensityItem addObject:item];
//    [self.videoSource pause];
    NSLog(@"DGCEffectCoreService--updateComposerNodeIntensity--path=%@--key=%@-value=%f",item.path,item.key,value);
    [self lockSDK];
    [self.manager updateComposerNodeIntensity:item.path key:item.key intensity:value];
    [self unlockSDK];
//    [self.videoSource resume];
}


- (void)updateComposerNodeIntensity:(NSString *)key path:(NSString *)path value: (float)value {
    if (_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSLog(@"DGCEffectCoreService--updateComposerNodeIntensity--path=%@--key=%@-value=%f",path,key,value);
    [self lockSDK];
    [self.manager updateComposerNodeIntensity:path key:key intensity:value];
    [self unlockSDK];
}


// 滤镜
- (void)updateFilterNodeIntensity:(DGCRTCEffectItem *)item value:(float)value {
    if (_isInitOK == false) { // 未初始化
        NSLog(@"DGCEffectCoreService--初始化失败..");
        return;
    }
    NSLog(@"DGCEffectCoreService--updateFilterNodeIntensity--path=%@--key=%@-value=%f",item.filterPath,item.key,value);
    [self lockSDK];
    [self.manager setFilterPath:item.filterPath];
    [self.manager setFilterIntensity:value];
    [self unlockSDK];
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


- (NSMutableArray *)arrayIndex:(NSMutableArray<NSString *> *)items {
    NSMutableArray *itemsArray = [NSMutableArray arrayWithArray:items];
    NSMutableArray *QualityArray = [[NSMutableArray alloc] init];
    NSArray *IDsArray = @[@"/palette/color", @"/palette/contrast", @"/palette/light",  @"/palette/vignette", @"/palette/particle"];
    for (int i=0; i<items.count; i++) {
        NSString * obj = items[i];
        for (int j=0; j<IDsArray.count; j++) {
            if ([obj isEqualToString:IDsArray[j]]) {
                [QualityArray addObject:obj];
                [itemsArray removeObject:obj];
            }
        }
    }
    NSMutableArray *itemsEndArray = [[NSMutableArray alloc] init];
    for (int j=0; j<IDsArray.count; j++) {
        for (int i=0; i<QualityArray.count; i++) {
            if (IDsArray[j] == QualityArray[i]) {
                [itemsEndArray addObject:QualityArray[i]];
            }
        }
    }
    [itemsArray addObjectsFromArray:itemsEndArray];
    return itemsArray;
}

- (void)lockSDK {
    [SDK_LOCK lock];
}

- (void)unlockSDK {
    [SDK_LOCK unlock];
}


- (CVPixelBufferRef)processWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(int)rotation timeStamp:(double)timeStamp {
    if (_isInitOK == false) { // 未初始化
//        NSLog(@"DGCEffectCoreService--初始化失败..");
        return pixelBuffer;
    }
    
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
//    double originTimestamp = timeStamp; // {zh} originTimestamp仅用于本地写入视频，其他依然使用timeStamp {en} originTimestamp is only used to write video, others still use timeStamp
//    if (self.videoSourceConfig.type == BEVideoSourceVideo) {
//        // {zh} 本地导入视频时，时间戳是从0开始，但是effect内部加了时间戳判断保护，会导致报错，上层兼容下 {en} if source is local video, timestamp start at 0 and the first frame is repeated three times, which conflicts with the protection inside Effect-SDK
//        timeStamp = [[NSDate date] timeIntervalSince1970];
//    }

    DGCBEPixelBufferInfo *pixelBufferInfo = [self.imageUtils getCVPixelBufferInfo:pixelBuffer];
    if (pixelBufferInfo.format != BE_BGRA) {
        pixelBuffer = [self.imageUtils transforCVPixelBufferToCVPixelBuffer:pixelBuffer outputFormat:BE_BGRA];
    }
    
    if (rotation != 0) {
        //  {zh} 特效 SDK 接收的纹理必须是正的，所以在调用 SDK 之前，需要先行旋转一下  {en} The texture received by the special effects SDK must be positive, so before calling the SDK, you need to rotate it first
        pixelBuffer = [self.imageUtils rotateCVPixelBuffer:pixelBuffer rotation:rotation];
    }
    id<BEGLTexture> texture = [self.imageUtils transforCVPixelBufferToTexture:pixelBuffer];
    DGCBEPixelBufferGLTexture *outTexture = nil;

    outTexture = [self.imageUtils getOutputPixelBufferGLTextureWithWidth:texture.width height:texture.height format:BE_BGRA withPipeline:self.manager.usePipeline];
    
//    self.manager.frontCamera = self.videoSource.frontCamera;
    int ret = [self.manager processTexture:texture.texture outputTexture:outTexture.texture width:texture.width height:texture.height rotate:[self getDeviceOrientation] timeStamp:timeStamp];
    if (ret != BEF_RESULT_SUC) {
        outTexture = texture;
    }
    CVPixelBufferRef outputPixelBuffer = outTexture.pixelBuffer;
    
    return outputPixelBuffer;
    
//    [self drawGLTextureOnScreen:outTexture rotation:0];
    
//    if (rotation != 0) {
//        CVPixelBufferRelease(pixelBuffer);
//    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[BEPreviewSizeManager singletonInstance] updateViewWidth:self.view.frame.size.width viewHeight:self.view.frame.size.height previewWidth:outTexture.width previewHeight:outTexture.height fitCenter:self.videoSourceConfig.type != BEVideoSourceCamera];
//    });
}


- (bef_ai_rotate_type)getDeviceOrientation {
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

//- (void)drawGLTextureOnScreen:(id<BEGLTexture>)texture rotation:(int)rotation {
//    [self.glView renderWithTexture:texture.texture size:CGSizeMake(texture.width, texture.height) applyingOrientation:rotation fitType:[self be_fitCenterDraw] ? 1 : 0];
//}

@end

