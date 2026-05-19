//
//  DGCRTCEffectItem.m
//  DGCRTC
//
//  Created by admin on 2024/8/9.
//

#import "DGCRTCEffectItem.h"

@interface DGCRTCEffectItem()
@property(assign,nonatomic) DGCRTCEffectItemType type; // 类型
@property(copy,nonatomic) NSString * path;

@property(copy,nonatomic) NSString * tag;

@property(copy,nonatomic) NSString * key; // key
@property(copy,nonatomic) NSString * makeupKey; // makeupKey
@property(copy,nonatomic) NSString * filterPath; // 滤镜path

@property(assign,nonatomic) CGFloat displayMin; //显示的起始数值
@property(assign,nonatomic) CGFloat displayRatio; //显示的比率

@property(assign,nonatomic) CGFloat makeupDisplayMin; //过滤显示的起始数值
@property(assign,nonatomic) CGFloat makeupDisplayRatio; //过滤显示的比率
@end

@implementation DGCRTCEffectItem

- (instancetype)initType:(DGCRTCEffectItemType)type{
    self = [super init];
    if (self) {
        self.type = type;
        [self handle];
    }
    return self;
}

#define be_beautyPath @"beauty_IOS_lite" // 美颜

#define reshape_litePath @"reshape_v8_lite" // 微整形 lite
#define whiten_teeth_IOS_litePath @"/whiten_teeth_IOS_lite" //白牙

#define beauty_4ItemsPath @"/beauty_4Items" // 微整形额外四项

//#define be_styleQualityPath @"/palette/color" // 画质


-(void)handle{
    self.displayRatio = 100;
    self.displayMin = 0;
    
    self.makeupDisplayRatio = 100;
    self.makeupDisplayMin = 0;
    
    switch (self.type) {
        case Dermabrasion: // 磨皮
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.6;
            self.path = be_beautyPath;
            self.key = @"smooth";
            break;
        case Whitening:{ // 美白
            break;
        }
            
        case Whitening_Nature: // 美颜 -- 美白 -- 自然
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = @"whiten_clear_IOS_lite";
            self.key = @"whiten";
            break;
        case Whitening_FairSkin: // 美颜 -- 美白 -- 白皙
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = @"beauty_IOS_lengbai_lite";
            self.key = @"whiten";
            break;
        case Whitening_PinkWhite: // 美颜 -- 美白 -- 粉白
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = @"beauty_IOS_fenbai_lite";
            self.key = @"whiten";
            break;
            
        case Sharpening: //锐化
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = be_beautyPath;
            self.key = @"sharp";
            break;
        case Clarity: // 清晰
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = be_beautyPath;
            self.key = @"clear";
            break;
            
        case BEF_BEAUTY_BODY_SHRINK_HEAD: // 小头
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = reshape_litePath;
            self.key = @"BEF_BEAUTY_BODY_SHRINK_HEAD";
            break;
        case Internal_Deform_CutFace: // 窄脸
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0;
            self.path = reshape_litePath;
            self.key = @"Internal_Deform_CutFace";
            break;
        case Internal_Deform_Face: // 瘦脸
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.3;
            self.path = reshape_litePath;
            self.key = @"Face_ALL_nature";
            break;
        case Internal_Deform_Zoom_Cheekbone: // 颧骨
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = reshape_litePath;
            self.key = @"Internal_Deform_Zoom_Cheekbone";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case Internal_Deform_Eye: // 眼睛大小
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.path = reshape_litePath;
            self.key = @"Internal_Deform_Eye";
//            self.isBidirectional = YES;
//            self.displayMin = -50;
            break;
            
        case Internal_Deform_Nose: // 鼻子大小
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = reshape_litePath;
            self.key = @"Internal_Deform_Nose";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
            
        case Internal_Deform_ZoomMouth: // 嘴巴大小
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = reshape_litePath;
            self.key = @"Internal_Deform_ZoomMouth";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case BEF_BEAUTY_WHITEN_TEETH: // 白牙
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.7;
            self.path = whiten_teeth_IOS_litePath;
            self.key = @"BEF_BEAUTY_WHITEN_TEETH";
            break;
            
            
            
        case ColorTemperature:
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = @"/palette/color";
            self.key = @"Intensity_Temperature";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case ColorTone:
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = @"/palette/light";
            self.key = @"Intensity_Hue";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case DegreeOfSaturation:
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = @"/palette/color";
            self.key = @"Intensity_Saturation";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case Brightness:
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = @"/palette/light";
            self.key = @"Intensity_Light";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case ContrastRatio:
            self.min = 0;
            self.start = 0.5;
            self.max = 1;
            self.value = 0.5;
            self.path = @"/palette/contrast";
            self.key = @"Intensity_Contrast";
            self.isBidirectional = YES;
            self.displayMin = -50;
            break;
        case Switch: // 在cell中设置 DGCBeautyFaceBottomBarListViewSwitchCell
//            imageName = "BeautyFace_Close"
//            name = DGCLocalizedString("已关闭")
            break;
            
            // 风格装
            
        case Baicha:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.4;
            
            self.makeupMin = 0;
            self.makeupStart = 0;
            self.makeupMax = 1;
            self.makeupValue = 1;
            
            self.path = @"/style_makeup/baicha";
            self.key = @"Filter_ALL";
            self.makeupKey = @"Makeup_ALL";
            break;
            
        case Ins2:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.4;
            
            self.makeupMin = 0;
            self.makeupStart = 0;
            self.makeupMax = 1;
            self.makeupValue = 1;
            
            self.path = @"/style_makeup/insfeng2";
            self.key = @"Filter_ALL";
            self.makeupKey = @"Makeup_ALL";
            break;
            
        case Wennuan:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.4;
            
            self.makeupMin = 0;
            self.makeupStart = 0;
            self.makeupMax = 1;
            self.makeupValue = 0.6;
            
            self.path = @"/style_makeup/wennuan";
            self.key = @"Filter_ALL";
            self.makeupKey = @"Makeup_ALL";
            break;
            
        case Cwei:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.4;
            
            self.makeupMin = 0;
            self.makeupStart = 0;
            self.makeupMax = 1;
            self.makeupValue = 0.6;
            
            self.path = @"/style_makeup/cwei";
            self.key = @"Filter_ALL";
            self.makeupKey = @"Makeup_ALL";
            break;
            
            // 滤镜
        case Chulian:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_49_4002";
            self.key = @"Filter_ALL";
            break;
            
        case Dongren:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_50_4003";
            self.key = @"Filter_ALL";
            break;
            
        case Haian:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_61_4014";
            self.key = @"Filter_ALL";
            break;
            
        case Liangju:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_9126008";
            self.key = @"Filter_ALL";
            break;
        case Liaoli:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649331";
            self.key = @"Filter_ALL";
            break;
            
        case Qipaoshui:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649337";
            self.key = @"Filter_ALL";
            break;
            
        case Qiangwei:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649342";
            self.key = @"Filter_ALL";
            break;
            
        case Qingyang:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649370";
            self.key = @"Filter_ALL";
            break;
            
        case Touliang:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649372";
            self.key = @"Filter_ALL";
            break;
            
        case Weixun:
            self.min = 0;
            self.start = 0;
            self.max = 1;
            self.value = 0.5;
            self.filterPath = @"/Filter_10649373";
            self.key = @"Filter_ALL";
            break;
            
        default:
            break;
    }
    
}

@end
