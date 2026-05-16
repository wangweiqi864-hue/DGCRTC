//
//  DGCRTCEffectItem.h
//  DGCRTC
//
//  Created by admin on 2024/8/9.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DGCRTCEffectItemType) {
    Switch = 0, // 开关
    
    Beauty = 100, // 美颜 --- 大分类
    Dermabrasion, // 美颜 -- 磨皮
    Whitening, // 美颜 -- 美白
    Sharpening, // 美颜 -- 锐化
    Clarity, // 美颜 -- 清晰
    Whitening_Nature, // 美颜 -- 美白 -- 自然
    Whitening_FairSkin, // 美颜 -- 美白 -- 白皙
    Whitening_PinkWhite, // 美颜 -- 美白 -- 粉白
    BEF_BEAUTY_BODY_SHRINK_HEAD, // 小头
    Internal_Deform_CutFace, // 窄脸
    Internal_Deform_Face, // 瘦脸
    Internal_Deform_Zoom_Cheekbone, // 颧骨
    Internal_Deform_Eye, // 眼睛大小
    Internal_Deform_Nose, // 鼻子大小
    Internal_Deform_ZoomMouth, // 嘴巴大小
    BEF_BEAUTY_WHITEN_TEETH, // 白牙
    
    
    MakeUp = 300, // 风格装
    Baicha, // 白茶
    Ins2, // INS风2
    Wennuan, // 温暖
    Cwei, // C位
    
    
    Quality = 200, // 画质 --- 大分类
    ColorTemperature, // 画质 -- 色温
    ColorTone, // 画质 -- 色调
    DegreeOfSaturation, // 画质 -- 饱和度
    Brightness, // 画质 -- 亮度
    ContrastRatio, // 画质 -- 对比度
    
    
    Filter = 400, // 滤镜
    Chulian, // 初恋
    Dongren, // 动人
    Haian, // 海岸
    Liangju, // 亮橘
    Liaoli, // 料理
    
    Qipaoshui, // 气泡水
    Qiangwei, // 蔷薇
    Qingyang, // 轻氧
    Touliang, // 透亮
    Weixun, // 微醺

};

NS_ASSUME_NONNULL_BEGIN




@interface DGCRTCEffectItem : NSObject

@property(copy,nonatomic,readonly) NSString * path;

@property(copy,nonatomic,readonly) NSString * tag;

@property(copy,nonatomic,readonly) NSString * key; // key
@property(copy,nonatomic,readonly) NSString * makeupKey; // 妆容key
@property(copy,nonatomic,readonly) NSString * filterPath; // 滤镜path

@property(assign,nonatomic) BOOL isBidirectional; // 是否双向

@property(assign,nonatomic,readonly) DGCRTCEffectItemType type; // 类型

@property(assign,nonatomic) CGFloat value; //当前的值
@property(assign,nonatomic) CGFloat min; //最小值
@property(assign,nonatomic) CGFloat max; //最大值
@property(assign,nonatomic) CGFloat start; //中间


@property(assign,nonatomic) CGFloat makeupValue; //当前的值
@property(assign,nonatomic) CGFloat makeupMin; //最小值
@property(assign,nonatomic) CGFloat makeupMax; //最大值
@property(assign,nonatomic) CGFloat makeupStart; //中间


@property(assign,nonatomic,readonly) CGFloat displayMin; //显示的起始数值
@property(assign,nonatomic,readonly) CGFloat displayRatio; //显示的比率

@property(assign,nonatomic,readonly) CGFloat makeupDisplayMin; //过滤显示的起始数值
@property(assign,nonatomic,readonly) CGFloat makeupDisplayRatio; //过滤显示的比率


-(instancetype)initType:(DGCRTCEffectItemType)type;

@end

NS_ASSUME_NONNULL_END
