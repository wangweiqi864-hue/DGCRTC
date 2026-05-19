//
//  DGCRTCAdapterProtocol.swift
//  ManGo
//
//  Created by mango-linwieyan on 2024/3/19.
//

import Foundation

//数据返回
struct DGCRTCAdapterResult {
    var msg : String = ""
    var code : Int = 0
}

protocol DGCRTCAdapterProtocol : NSObjectProtocol  {
    
    var dataSource : DGCRTCAdapterDataSource{get set}
    
    //安装sdk
    func setupSDK(appID : String,appKey : String)
    
    /// 刷新token
    func refreshSDK(appID : String,appKey : String)
    
    // 设置sdk对 Audio Session 操作权限
    func setAudioSessionOperationRestriction(restriction: DGCAudioSessionOperationRestriction)
    
    /// 是否可以发布流
    func enablePublish(isEnablePublish : Bool)
    
    /// 设置美颜
    func enableSetBeauty(isSetBeauty : Bool)
    
    //是否可以使用mic
//    func enableMic(isEnableMic : Bool)
//    //是否可以使用伴奏
    func enableBackMusic(isEnableBackMusic : Bool)
    
//    /// 更新音频流状态
//    func uploadLocalAudioStream()
//    
//    /// 更新视频流状态
//    func uploadLocalVideoStream()
    
    //同时 是否可以使用mic 是否可以使用伴奏,是否开麦
//    func enable(isEnableMic: Bool,isEnableBackMusic : Bool, isOpenMic:Bool)
    
    //开启/关闭声音
    func openRemoteAudio(_ isMute : Bool)
    
    //开启/关闭麦克风
    func openMic(_ isOpen : Bool)
    
    //设置音量
    func setSpeakerVolume(_ volume : Int)
    
    //静音自己的声音
    func setSpeakerMute()
    
    //进入房间
    func joinRoom()
    
    //退出房间
    func quitRoom(isDestroySDK : Bool)
    
    ///----伴奏相关
    //播放伴奏 loop循环次数 -1无限循环
    func playBackMusic(musicPath:String,loop:Int)->Int
    //暂停伴奏
    func pauseBackMusic() -> Int
    //恢复伴奏
    func resumeBackMusic() -> Int
    //停止伴奏
    func stopBackMusic() -> Int

    //设置伴奏音量
    func setBackMusicVolume(volume:Int) -> Int
    //获取当前伴奏音量
//    func getCurrentBackMusicVolume() -> Int
    //设置伴奏进度 时间 单位ms
    func setBackMusicProgress(progress:Float) -> Int
    //获取当前伴奏的总时间 单位ms
    func getCurrentBackMusicDuration() -> Int
    //获取当前伴奏的播放时间 单位ms
    func getCurrentBackMusicCurrentPosition() -> Int
    
    // 视频相关
//    func startPreview()
    
    func stopPreview(isDestroySDK : Bool)
    
    func setLocalView(view : UIView)
    
    func setRemoteView(view : UIView,uId : Int64)
    
    @discardableResult
    func openCameraSwitch(_ isOpen : Bool) -> Bool
    
    func switchCamera(isFront : Bool)
    
    func setLocalRenderMode(isMirror : Bool)
    
    /// 是否启用视频模块
    func enableVideo(isEnableVideo : Bool)
    
    func setVideoEncodeConfig(config : DGCRTCManagerVideoEncodeConfig)
    
    
    // 加入多频道
    // roomID 需要加入的房间ID
    // token 新频道的token
    func joinChannelExt(roomId: Int64, token: String)
    
    // 退出多频道
    func leaveChannelExt(roomId : Int64)
    
    // 退出所有多频道
    func leaveChannelAllExt()
    
    // 静音其他频道
    func openExtAudio(roomId: Int64, _ isMute: Bool)
    
    func setExtRemoteView(view: UIView, uId: Int64, roomId: Int64)
    
    func enableAIAinsMode(isEnableAIAinsMode: Bool,mode:Int32)
}


//声音数据源
protocol DGCRTCAdapterDataSource {
    
    //获取当前用户ID
    func adapterGetPlayerID() -> Int64
    //获取房间ID
    func adapterGetCurrentRoomId() -> Int64
    
    //获取token
    func adapterNewToken() -> String
    
    //声网降噪mode
    func agoMode() -> Int32
    
    //是否开关降噪
    func isClosed4AINoisereduction() -> Bool
}


protocol DGCRTCAAdapterDelegate {
    
    //进入成功
    func rtcAdapterEnterRoomSuccessedWithResult(_ result : DGCRTCAdapterResult?, _ roomid : Int64)
    
    //失败回调
    func rtcAdapterEnterRoomFailedWithResult(_ result : DGCRTCAdapterResult?)
    
    //链接断开
    func rtcAdapterDisConnect(_ result : DGCRTCAdapterResult?)
    
    //回调说话状态
    func rtcAdapterSpeakerStatus(_ volume : CGFloat,_ uId : Int64)
    
    // 多频道 回调说话状态
    func rtcAdapterExtSpeakerStatus(_ volume : CGFloat,_ uId : Int64)
    
    /// 显示首帧画面回调
    func rtcAdapterSpeaker(showFirstFrame uId : Int64)
    
    // 伴奏播放完成
    func rtcAdapterBackMusicFinished(_ fPath:String?)
    // 伴奏播放进度回调
    func rtcAdapterBackMusicPositionChanged(postion: Int, total: Int)
    
    //是否启动了伴奏
    func rtcAdapterIsEnableBackMusic() -> Bool
    
    //是否启动了麦克风 表明是 主播角色在麦上
//    func rtcAdapterIsEnableMic() -> Bool
    
    func rtcAdapterIsEnablePublish() -> Bool
    
    // 是否启用摄像头
    func rtcAdapterIsEnableCamera() -> Bool
    
    func rtcAdapterIsLive() -> Bool
    
    /// 是否可用说话
    func rtcAdapterIsOpenSpeaker() -> Bool
    
    /// 获取讲话音量
    func rtcAdapterSpeakerVolum() -> Int
    
    /// 获取伴奏音量
    func rtcAdapterBackMusicVolum() -> Int
    
    /// 是否是否镜像
    func rtcAdapterIsMirror() -> Bool
    
    // 获取配置
    func rtcAdapterGetConfig() ->  DGCRTCManagerConfig
    
    // 获取是否是前置摄像头
    func rtcAdapterIsCameraFront() ->  Bool
    /// 是否启用美颜
    func rtcAdapterIsEnableSetBeauty() -> Bool
}

