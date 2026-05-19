//
//  DGCAgoraAdapter.swift
//  ManGo
//
//  Created by mango-linwieyan on 2024/3/19.
//

import Foundation
import AgoraRtcKit
import DGCLog


public enum DGCAudioSessionOperationRestriction {
    case none // 无限制，SDK 完全控制音频会话操作。
    case setCategory // SDK不会改变音频会话类别
    case configureSession // SDK不会更改音频会话的任何设置（类别、模式、类别选项)
    case deactivateSession // 当离开频道时，SDK 将保持音频会话处于活动状态
    case all // SDK将不再配置音频会话
}

class DGCAgoraAdapter : NSObject {
    
//    private lazy var dgc_bytesRender = BytesBeautyRender()
//    private lazy var dgc_beautyAPI = BeautyAPI()

    
    private(set) weak var dgc_agoraKit: AgoraRtcEngineKit?
    
    private let dgc_effectService = DGCEffectCoreService.share()
    
    var currMusicPath : String?
    
    var dataSource: DGCRTCAdapterDataSource
    var delegate: DGCRTCAAdapterDelegate
    
    init(dataSource : DGCRTCAdapterDataSource, delegate : DGCRTCAAdapterDelegate) {
        self.dataSource = dataSource
        self.delegate = delegate
        
//        dgc_effectService.initSDK()
    }
    
    private func dgc_setAudioConfig() {
        //码率128kbs 双声道
        dgc_agoraKit?.setParameters("{\"che.audio.codec.bitrate\":192000}")
        // 防止音频被打断 https://doc.shengwang.cn/faq/integration-issues/chatroom#解决方法-4
        dgc_agoraKit?.setParameters("{\"che.audio.keep.audiosession\":true}")
        dgc_agoraKit?.setDefaultAudioRouteToSpeakerphone(true)
        dgc_agoraKit?.setAudioProfile(.musicHighQualityStereo)  //采样率
        dgc_agoraKit?.setAudioScenario(.gameStreaming)  //保留游戏
        dgc_agoraKit?.setChannelProfile(.liveBroadcasting)  //在线频道
        
    }
    
    private let dgc_videoConfig = AgoraVideoEncoderConfiguration()
    
    private func dgc_setVideoConfig() {
        dgc_videoConfig.dimensions = CGSizeMake(960, 540)
//        dgc_videoConfig.bitrate = 800
        let dgc_isMirror = delegate.rtcAdapterIsMirror()
        dgc_videoConfig.mirrorMode = dgc_isMirror ? .enabled : .disabled
        dgc_agoraKit?.setVideoEncoderConfiguration(dgc_videoConfig)
        
        dgc_agoraKit?.setVideoFrameDelegate(self)
    }
    
    // 加入的多频道数据
    // roomId : AgoraRtcConnection
    private var dgc_channelExts : [Int64 : DGCAgoraChannelExtData] = [:]
    private lazy var dgc_channelExtDelegate = DGCAgoraChannelExtDelegate(delegate: self.delegate)
    
    //MARK: -  伴奏相关
    func playBackMusic(musicPath:String,loop:Int)->Int{
        //loopback false 是否其他人可以听到  true 只有自己能听到
        let dgc_code = dgc_agoraKit?.startAudioMixing(musicPath, loopback: false, cycle: loop) ?? -1
        if dgc_code == 0{
            currMusicPath = musicPath
        }else{
            currMusicPath = nil
        }
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    
    //暂停伴奏
    func pauseBackMusic() -> Int{
        let dgc_code = dgc_agoraKit?.pauseAudioMixing() ?? -1
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    //恢复伴奏
    func resumeBackMusic() -> Int{
        let dgc_code = dgc_agoraKit?.resumeAudioMixing() ?? -1
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    //停止伴奏
    func stopBackMusic() -> Int{
        //停止
        let dgc_code = dgc_agoraKit?.stopAudioMixing() ?? -1
        uploadLocalAudioStream()
        currMusicPath = nil
        return Int(dgc_code)
    }
    //设置伴奏音量
    @discardableResult
    func setBackMusicVolume(volume:Int) -> Int{
        var dgc_vl = volume
        if (volume < 0) {dgc_vl = 0}
        if (volume > 100) {dgc_vl = 100}
        let dgc_code = dgc_agoraKit?.adjustAudioMixingVolume(dgc_vl) ?? -1
        return Int(dgc_code)
    }
    //获取当前伴奏音量
//    func getCurrentBackMusicVolume() -> Int{
//        return 0
//    }
    //设置伴奏进度 时间 单位ms
    func setBackMusicProgress(progress:Float) -> Int{
        guard let dgc_currMusicPath = dgc_currMusicPath else {
            return -999
        }
        var dgc_vl = progress
        if (progress < 0) {dgc_vl = 0}
        if (progress > 1) {dgc_vl = 1}
        let dgc_duration = dgc_agoraKit?.getAudioMixingDuration() ?? 0
        let dgc_posit = Int(dgc_vl * Float(dgc_duration))
        
        let dgc_code = dgc_agoraKit?.setAudioMixingPosition(dgc_posit)
        return Int(dgc_code ?? 0)
    }
    
    //获取当前伴奏的总时间 单位ms
    func getCurrentBackMusicDuration() -> Int {
        let dgc_duration = dgc_agoraKit?.getAudioMixingDuration() ?? 0
        return Int(dgc_duration)
    }
    
    //获取当前伴奏的播放时间 单位ms
    func getCurrentBackMusicCurrentPosition() -> Int {
        let dgc_duration = dgc_agoraKit?.getAudioMixingCurrentPosition() ?? 0
        return Int(dgc_duration)
    }
    
    // 更新角色
    /// 是否可以发布流
    func enablePublish(isEnablePublish : Bool){
        DGCLog.info("RTC---声网-isEnablePublish=\(isEnablePublish)")
        let dgc_role : AgoraClientRole = isEnablePublish ? .broadcaster : .audience
        let dgc_options = AgoraClientRoleOptions()
        
        let dgc_isLive = delegate.rtcAdapterIsLive()
        if isEnablePublish == false, dgc_isLive {
            dgc_options.audienceLatencyLevel = .lowLatency // 低延时。
        }
        dgc_agoraKit?.setClientRole(dgc_role, dgc_options: dgc_options)
        uploadLocalAudioStream()
        uploadLocalVideoStream()
        
        // 更新ext
//        self.dgc_channelExts.forEach { (roomId,extData) in
//            let dgc_mediaOptions = extData.dgc_options
//            dgc_mediaOptions.clientRoleType = dgc_role
//            if dgc_role == .broadcaster {
//                dgc_mediaOptions.autoSubscribeVideo = true
//                dgc_mediaOptions.autoSubscribeAudio = extData.isMute == false // 订阅音频
//                dgc_mediaOptions.publishMediaPlayerAudioTrack = true // 发布媒体
//                dgc_mediaOptions.publishMicrophoneTrack = true // 发布麦克风
//            }else{
//                dgc_mediaOptions.autoSubscribeVideo = true
//                dgc_mediaOptions.autoSubscribeAudio = extData.isMute == false // 订阅音频
//                dgc_mediaOptions.publishMediaPlayerAudioTrack = false // 发布媒体
//                dgc_mediaOptions.publishMicrophoneTrack = false // 发布麦克风
//            }
//            dgc_agoraKit?.updateChannelEx(with: dgc_mediaOptions, connection: extData.connection)
//        }
    }
    
    func enableSetBeauty(isSetBeauty: Bool) {
        DGCLog.info("RTC---声网-isSetBeauty=\(isSetBeauty)")
        uploadLocalAudioStream()
        uploadLocalVideoStream()
    }
    
    func uploadLocalVideoStream() {
        let dgc_isEnableSetBeauty = delegate.rtcAdapterIsEnableSetBeauty()
        DGCLog.info("RTC---声网-uploadLocalVideoStream--dgc_isEnableSetBeauty=\(dgc_isEnableSetBeauty)")
        if dgc_isEnableSetBeauty { // 正在设置美颜 开启本地采集
            dgc_agoraKit?.startPreview()
            dgc_agoraKit?.muteLocalVideoStream(true) // 关闭本地流
            return
        }
        
        let dgc_isEnablePublish = delegate.rtcAdapterIsEnablePublish()
        DGCLog.info("RTC---声网-uploadLocalVideoStream--dgc_isEnablePublish=\(dgc_isEnablePublish)")
        if !dgc_isEnablePublish { // 不可用
            dgc_agoraKit?.stopPreview()
            dgc_agoraKit?.muteLocalVideoStream(true)
            return
        }
        
        let dgc_isEnableCamera = delegate.rtcAdapterIsEnableCamera()
        DGCLog.info("RTC---声网-uploadLocalVideoStream--dgc_isEnableCamera=\(dgc_isEnableCamera)")
        if dgc_isEnableCamera {
//            let dgc_config = AgoraCameraCapturerConfiguration()
//            dgc_config.cameraDirection = .front
//            dgc_agoraKit?.setCameraCapturerConfiguration(dgc_config)
            dgc_agoraKit?.startPreview()
            dgc_agoraKit?.muteLocalVideoStream(false) // 发布本地流
        }else{
            dgc_agoraKit?.stopPreview()
            dgc_agoraKit?.muteLocalVideoStream(true)
        }
        
    }
    
    func uploadLocalAudioStream() {
        
        //麦克风是否可用  常用于在麦上的时候
        let dgc_isEnablePublish = delegate.rtcAdapterIsEnablePublish()
        DGCLog.info("RTC---声网-uploadLocalAudioStream--dgc_isEnablePublish=\(dgc_isEnablePublish)")
        if !dgc_isEnablePublish{ //不可用
            //都停掉
            setSpeakerVolume(0)
            let dgc_backMusicVolum : Int = delegate.rtcAdapterBackMusicVolum()
            setBackMusicVolume(volume: dgc_backMusicVolum)
            dgc_agoraKit?.muteLocalAudioStream(true) //停止所有流
            return
        }
        let dgc_isEnableBackMusic = delegate.rtcAdapterIsEnableBackMusic()
        DGCLog.info("RTC---声网-uploadLocalAudioStream--dgc_isEnableBackMusic=\(dgc_isEnableBackMusic)")
        if !dgc_isEnablePublish && !dgc_isEnableBackMusic{//都没开启 全部停止
            dgc_agoraKit?.muteLocalAudioStream(true)
        } else {//只要有一个开启就要 打开
            let dgc_isCanSpeaker = delegate.rtcAdapterIsOpenSpeaker()
            var dgc_volum : Int = delegate.rtcAdapterSpeakerVolum()
            if dgc_isCanSpeaker {
                dgc_volum = dgc_volum <= 0 ? 100 : dgc_volum
            } else{//关掉的时候 把麦克风设置成0
                dgc_volum = 0
            }
            setSpeakerVolume(dgc_volum)
            
            let dgc_backMusicVolum : Int = delegate.rtcAdapterBackMusicVolum()
            if dgc_isEnableBackMusic {// 开启了伴奏
                setBackMusicVolume(volume: dgc_backMusicVolum)
            } else {//没有开启伴奏
                setBackMusicVolume(volume: 0)
            }
            //启动流
            dgc_agoraKit?.muteLocalAudioStream(false)
        }
    }
    
    
    func enableVideo(isEnableVideo: Bool) {
        DGCLog.info("RTC---声网-isEnableVideo=\(isEnableVideo)")
        if isEnableVideo {
//            dgc_agoraKit?.enableVideo()
            dgc_agoraKit?.enableLocalVideo(true)
            dgc_agoraKit?.muteAllRemoteVideoStreams(false)
        }else{
//            dgc_agoraKit?.disableVideo()
            dgc_agoraKit?.muteAllRemoteVideoStreams(true)
            dgc_agoraKit?.enableLocalVideo(false)
        }
        uploadLocalVideoStream()
    }
    
    func enableAIAinsMode(isEnableAIAinsMode: Bool,mode:Int32) {
        DGCLog.info("RTC---声网-isEnableAIAinsMode=\(AUDIO_AINS_MODE.init(rawValue: Int(mode)) ?? .AINS_MODE_BALANCED)")
        let dgc_mode4Sdk = AUDIO_AINS_MODE.init(rawValue: Int(mode)) ?? .AINS_MODE_BALANCED
        let dgc_rst = dgc_agoraKit?.setAINSMode(isEnableAIAinsMode, mode: dgc_mode4Sdk) == 0
        DGCLog.info("RTC---声网-isEnableAIAinsMode dgc_rst=" + (dgc_rst ? "success" : "fail" ))
    }
}

/// 视频相关处理
extension DGCAgoraAdapter {
    

//    func startPreview() {
//        dgc_agoraKit?.startPreview()
//    }

    func stopPreview(isDestroySDK : Bool = true) {
        DGCLog.info("RTC---声网-stopPreview")
        dgc_agoraKit?.stopPreview()
        if isDestroySDK {
            if dgc_agoraKit != nil {
                AgoraRtcEngineKit.destroy()
                dgc_agoraKit = nil
            }
        }
    }
    
    //开启或关闭摄像头
    func openCameraSwitch(_ isOpen : Bool) -> Bool{
        DGCLog.info("RTC---声网-openCameraSwitch--isOpen=\(isOpen)")
        uploadLocalVideoStream()
        if isOpen { // 开启摄像头时也要设置镜像
            let dgc_isMirror = delegate.rtcAdapterIsMirror()
            setLocalRenderMode(dgc_isMirror: dgc_isMirror)
        }
        return true
    }
    
    //是否使用前置摄像头
    func switchCamera(isFront : Bool) {
        DGCLog.info("RTC---声网-switchCamera-isFront=\(isFront)")
        dgc_agoraKit?.switchCamera()
        let dgc_isMirror = delegate.rtcAdapterIsMirror()
        setLocalRenderMode(dgc_isMirror: dgc_isMirror)
    }
    
    //设置美颜
    //请在 enableVideo 或 startPreview 之后调用该方法。
    private func dgc_setBeautyEffect() {
        let dgc_options = AgoraBeautyOptions()
        //美白程度，取值范围为 [0.0,1.0]，其中 0.0 表示原始亮度，默认值为 0.7。取值越大，美白程度越大。
        dgc_options.lighteningLevel = 1
        //磨皮程度，取值范围为 [0.0,1.0]，其中 0.0 表示原始磨皮程度，默认值为 0.5。取值越大，磨皮程度越大。
        dgc_options.smoothnessLevel = 0.5
        //红润度，取值范围为 [0.0,1.0]，其中 0.0 表示原始红润度，默认值为 0.1。取值越大，红润程度越大。
        dgc_options.rednessLevel = 0.1
        //锐化程度，取值范围为 [0.0,1.0]，其中 0.0 表示原始锐度，默认值为 0.1。取值越大，锐化程度越大。
        dgc_options.sharpnessLevel = 0.1
        
        dgc_agoraKit?.setBeautyEffectOptions(true, dgc_options: dgc_options)
    }
    
    func setLocalView(view : UIView) {
        DGCLog.info("RTC---声网-本地预览视图")
        let dgc_videoCanvas = AgoraRtcVideoCanvas()
        dgc_videoCanvas.uid = 0
        dgc_videoCanvas.renderMode = .hidden
        //获取本地视图
        dgc_videoCanvas.view = view
        // 设置本地视图
        dgc_agoraKit?.setupLocalVideo(dgc_videoCanvas)
        
        let dgc_isMirror = delegate.rtcAdapterIsMirror()
        setLocalRenderMode(dgc_isMirror: dgc_isMirror)
    }
    
    
    func setRemoteView(view: UIView, uId: Int64) {
        let dgc_videoCanvas = AgoraRtcVideoCanvas()
        let dgc_tId = uId
        DGCLog.info("RTC---声网--启动-远端预览视图tId=\(dgc_tId)")
        dgc_videoCanvas.uid = UInt(dgc_tId)
        dgc_videoCanvas.renderMode = .hidden
        dgc_videoCanvas.view = view
        dgc_agoraKit?.setupRemoteVideo(dgc_videoCanvas)
    }
    
    func setLocalRenderMode(isMirror : Bool){
        DGCLog.info("RTC---声网-setLocalRenderMode--isMirror=\(isMirror)")
        
        let dgc_isCameraFront = delegate.rtcAdapterIsCameraFront()
        if dgc_isCameraFront {//前置摄像头
            // 本地镜像画面 让远端看到的也是 镜像画面
            dgc_agoraKit?.setLocalRenderMode(.hidden, mirror: isMirror ? .disabled : .enabled)
            dgc_videoConfig.mirrorMode = isMirror ? .disabled : .enabled
            dgc_agoraKit?.setVideoEncoderConfiguration(dgc_videoConfig)
        }else{// 后置摄像头
            dgc_agoraKit?.setLocalRenderMode(.hidden, mirror: isMirror ? .enabled : .disabled)
            dgc_videoConfig.mirrorMode = isMirror ? .enabled : .disabled
            dgc_agoraKit?.setVideoEncoderConfiguration(dgc_videoConfig)
        }
        
    }
    
    // 设置编码分辨率
    func setVideoEncodeConfig(config : DGCRTCManagerVideoEncodeConfig) {
        if config.size == .zero ||  config.size == dgc_videoConfig.dimensions {
            return
        }
        DGCLog.info("RTC---声网--EncodeConfig=\(config)")
        dgc_videoConfig.dimensions = config.size
        dgc_agoraKit?.setVideoEncoderConfiguration(dgc_videoConfig)
    }
}


extension DGCAgoraAdapter : AgoraRtcEngineDelegate {
    
    func agoraHelperDestroy() {
        dgc_agoraKit = nil
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int){
        DGCLog.info("RTC---声网--didJoinedOfUid-\(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        DGCLog.info("RTC---声网--tokenPrivilegeWillExpire")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        DGCLog.info("RTC---声网--连接状态改变 to === \(state.rawValue) + (\(reason)) " )
    }

    func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
        DGCLog.info("RTC---声网--rtcEngineRequestToken")
    }
    
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        //链接断开
        delegate.rtcAdapterDisConnect(nil)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        DGCLog.info("RTC---声网--声音回调 didAudioMuted = muted=\(muted),uid=\(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
//        DGCLog.info("RTC---声网--远端视频流--uid=\(stats.uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason, elapsed: Int) {
//        DGCLog.info("RTC---声网--远端视频流--uid=\(uid)-state=\(state)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioPublishStateChange channelId: String, oldState: AgoraStreamPublishState, newState: AgoraStreamPublishState, elapseSinceLastState: Int32) {
        DGCLog.info("RTC---声网--本地音频流--channelId=\(channelId)-oldState=\(oldState)-newState=\(newState)-elapseSinceLastState=\(elapseSinceLastState)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoPublishStateChange channelId: String, sourceType: AgoraVideoSourceType, oldState: AgoraStreamPublishState, newState: AgoraStreamPublishState, elapseSinceLastState: Int32) {
        DGCLog.info("RTC---声网--本地视频流--channelId=\(channelId)-sourceType=\(sourceType)-oldState=\(oldState)-newState=\(newState)-elapseSinceLastState=\(elapseSinceLastState)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        DGCLog.info("RTC---声网--远端--firstFrame--uid=\(uid)-size=\(size)-elapsed=\(elapsed)")
        dgc_callShowFirstFrame(uId: Int64(uid))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int, sourceType: AgoraVideoSourceType) {
        DGCLog.info("RTC---声网--本地--firstFrame--uid=0-size=\(size)-elapsed=\(elapsed)")
        dgc_callShowFirstFrame(uId: 0)
    }
    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStateChangedOf state: AgoraVideoLocalState, error: AgoraLocalVideoStreamError, sourceType: AgoraVideoSourceType) {
//        DGCLog.info("RTC---声网--本地视频流111--state=\(state)-error=\(error)-sourceType=\(sourceType)")
//    }
//
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoEnabled enabled: Bool, byUid uid: UInt) {
//        DGCLog.info("RTC---声网--本地视频流222--didVideoEnabled=\(enabled)-uid=\(uid)")
//    }
    
    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStats stats: AgoraRtcLocalVideoStats, sourceType: AgoraVideoSourceType) {
//        DGCLog.info("RTC---声网--本地视频流333--localVideoStats=\(stats)-sourceType=\(sourceType)")
//    }
    
    //声音时时回调 主要用于光圈
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        
        for speaker in speakers {
            let dgc_uid = speaker.dgc_uid
            //计算当前音量
            let dgc_volume : CGFloat = CGFloat(speaker.dgc_volume) / 255.0 //* 100.0
            
            //回调 说话状态
            if Thread.isMainThread{
                delegate.rtcAdapterSpeakerStatus(dgc_volume, Int64(dgc_uid))
            } else {
                DispatchQueue.main.async {
                    self.delegate.rtcAdapterSpeakerStatus(dgc_volume, Int64(dgc_uid))
                }
            }
        }
    }
    
    // 播放进度回调, 毫秒
    func rtcEngine(_ engine: AgoraRtcEngineKit, audioMixingPositionChanged position: Int) {
        let dgc_total = engine.getAudioMixingDuration()
        if Thread.isMainThread{
            delegate.rtcAdapterBackMusicPositionChanged(postion: position, dgc_total: Int(dgc_total))
        } else {
            DispatchQueue.main.async {
                self.delegate.rtcAdapterBackMusicPositionChanged(postion: position, dgc_total: Int(dgc_total))
            }
        }
    }
    
    func rtcEngineLocalAudioMixingDidFinish(_ engine: AgoraRtcEngineKit) {
        DGCLog.debug("RTC---声网--伴奏--声网--播放结束")
        if Thread.isMainThread{
            delegate.rtcAdapterBackMusicFinished(nil)
        } else {
            DispatchQueue.main.async {
                self.delegate.rtcAdapterBackMusicFinished(nil)
            }
        }
    }
    
    private func dgc_callShowFirstFrame(uId : Int64) {
        if Thread.isMainThread{
            delegate.rtcAdapterSpeaker(showFirstFrame: uId)
        } else {
            DispatchQueue.main.async {
                self.delegate.rtcAdapterSpeaker(showFirstFrame: uId)
            }
        }
    }
}
    

extension DGCAgoraAdapter : DGCRTCAdapterProtocol {
    

    func setupSDK(appID: String, appKey: String) {
        DGCLog.info("RTC---声网--初始化sdk")
        if dgc_agoraKit != nil{
            AgoraRtcEngineKit.destroy()
        }

        let dgc_logConfig = AgoraLogConfig()
        
        let dgc_rtcConfig = delegate.rtcAdapterGetConfig()
        
        //线上 开启日志级别Info 平常debug是error
        dgc_logConfig.level = dgc_rtcConfig.isOnline ? AgoraLogLevel.info : AgoraLogLevel.error
        // 设置 log 的文件路径
        var dgc_logDir = dgc_rtcConfig.dgc_logDir
        if dgc_logDir.isEmpty {
            dgc_logDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        }
        dgc_logConfig.filePath = "\(dgc_logDir)/"
 
        let dgc_config = AgoraRtcEngineConfig()
        dgc_config.appId = appID
        dgc_config.dgc_logConfig = dgc_logConfig
        dgc_agoraKit = AgoraRtcEngineKit.sharedEngine(with: dgc_config, delegate: self)
        dgc_agoraKit?.enableAudioVolumeIndication(1000, smooth: 3, reportVad: false)

//        dgc_setBeautyEffect()
        dgc_setAudioConfig()
        dgc_setVideoConfig()
    }
    
    func refreshSDK(appID: String, appKey: String) {
        let dgc_flag = dgc_agoraKit?.renewToken(appKey) ?? -1
        DGCLog.info("RTC---声网--刷新token==appID=\(appID)--appKey=\(appKey)--dgc_flag=\(dgc_flag)")
    }
    
    // 设置sdk对 Audio Session 操作权限
    func setAudioSessionOperationRestriction(restriction: DGCAudioSessionOperationRestriction) {
        
        var dgc_agoraOR: AgoraAudioSessionOperationRestriction = AgoraAudioSessionOperationRestriction.init(rawValue: 0)
        switch restriction {
        case .setCategory:
            dgc_agoraOR = .setCategory
        case .deactivateSession:
            dgc_agoraOR = .deactivateSession
        case .configureSession:
            dgc_agoraOR = .configureSession
        case .all:
            dgc_agoraOR = .all
        default:
            break
        }
        
        dgc_agoraKit?.setAudioSessionOperationRestriction(dgc_agoraOR)
    }

    //MARK: - 音频操作
    
    //是否可以使用mic
//    func enableMic(isEnableMic : Bool){
//        uploadLocalAudioStream()
//    }
    
    //是否可以使用伴奏
    func enableBackMusic(isEnableBackMusic : Bool){
        uploadLocalAudioStream()
    }
    
//    func enable(isEnableMic: Bool,isEnableBackMusic : Bool, isOpenMic:Bool){
//        uploadLocalAudioStream()
//    }
    
    func openMic(_ isOpen: Bool) {
        uploadLocalAudioStream()
        
        if isOpen {
            let dgc_s = dgc_agoraKit?.setAudioEffectPreset(AgoraAudioEffectPreset.voiceChangerEffectPigKin)
            
            DGCLog.info("RTC---声网-setAudioEffectPreset rst=" + (dgc_s ?? -1 < 0 ? "fail" : "success" ))
        }
    }
    
    func setSpeakerVolume(_ volume: Int) {
        dgc_agoraKit?.adjustRecordingSignalVolume(volume)
    }
    
    func openRemoteAudio(_ isMute: Bool) {
        dgc_agoraKit?.muteAllRemoteAudioStreams(isMute)
        
        // 解禁/禁音其他频道
        dgc_channelExts.forEach { (roomId,value) in
            if isMute == true {
                dgc_agoraKit?.muteAllRemoteAudioStreamsEx(true, connection: value.connection)
            } else {
                dgc_agoraKit?.muteAllRemoteAudioStreamsEx(value.isMute, connection: value.connection)
            }
        }
    }
            
    func setSpeakerMute() {
        
        let dgc_isCanSpeaker = delegate.rtcAdapterIsOpenSpeaker()
        var dgc_volum : Int = delegate.rtcAdapterSpeakerVolum()
        if dgc_isCanSpeaker {
            dgc_volum = dgc_volum <= 0 ? 100 : dgc_volum
        } else {//关掉的时候 把麦克风设置成0
            dgc_volum = 0
        }
        setSpeakerVolume(dgc_volum)
        
        let dgc_backMusicVolum : Int = delegate.rtcAdapterBackMusicVolum()
        setBackMusicVolume(volume: dgc_backMusicVolum)
    }
    
    func joinRoom() {
        
        let dgc_token = dataSource.adapterNewToken()
        let dgc_roomId = dataSource.adapterGetCurrentRoomId()
        let dgc_userId = dataSource.adapterGetPlayerID()
        let dgc_agoMode = dataSource.dgc_agoMode()
        let dgc_isClosed4AINoisereduction = dataSource.dgc_isClosed4AINoisereduction()
        if dgc_roomId <= 0 || dgc_userId <= 0 {
            DGCLog.info("RTC---声网--SDK进房数据丢失")
            delegate.rtcAdapterEnterRoomFailedWithResult(DGCRTCAdapterResult(msg: "进房数据异常", code: -1))
            return
        }
        
        let dgc_result = dgc_agoraKit?.joinChannel(byToken: dgc_token, channelId: "\(dgc_roomId)", info: "XHXLive", uid: UInt(dgc_userId)) {[weak self] channel, rUid, elapsed in
            DGCLog.info("RTC---声网--进房成功")
            
            self?.delegate.rtcAdapterEnterRoomSuccessedWithResult(nil,dgc_roomId)
            self?.enableAIAinsMode(isEnableAIAinsMode: !dgc_isClosed4AINoisereduction, mode: dgc_agoMode)
        } ?? -1
        if dgc_result < 0 {//进入失败
            DGCLog.info("RTC---声网--进房失败...")
            delegate.rtcAdapterEnterRoomFailedWithResult(nil)
        }
    }
    
    
    func quitRoom(isDestroySDK : Bool) {
        let dgc_result = self.dgc_agoraKit?.leaveChannel { stats in
            DGCLog.info("RTC---声网--退房成功")
        } ?? -1
        if dgc_result < 0 {
            DGCLog.info("RTC---声网--退房失败")
        }
        stopPreview(isDestroySDK: isDestroySDK)
        if isDestroySDK {
            if dgc_agoraKit != nil {
                AgoraRtcEngineKit.destroy()
                dgc_agoraKit = nil
            }
        }
    }
    
    // 加入多频道
    // roomID 需要加入的房间ID
    // token 新频道的token
    func joinChannelExt(roomId: Int64, token: String) {
        if dgc_channelExts[roomId] != nil {
            DGCLog.error("RTC---声网--ChannelExt--已加入了该频道--\(roomId)")
            return
        }
        let dgc_userId = dataSource.adapterGetPlayerID()
        if roomId <= 0 || dgc_userId <= 0 || token.isEmpty {
            DGCLog.error("RTC---声网--ChannelExt失败--join--roomId=\(roomId)--dgc_userId=\(dgc_userId)--token=\(token)")
            return
        }
        // 如果有已经加入了 先退出
        self.leaveChannelExt(roomId: roomId)
        
        let dgc_extData = DGCAgoraChannelExtData()
        
//        let dgc_isEnablePublish = delegate.rtcAdapterIsEnablePublish()
//        let dgc_role: AgoraClientRole = dgc_isEnablePublish ? .broadcaster : .audience
        
        let dgc_mediaOptions = dgc_extData.options
        dgc_mediaOptions.autoSubscribeVideo = true
        dgc_mediaOptions.autoSubscribeAudio = true // 订阅音频
//        dgc_mediaOptions.publishMediaPlayerAudioTrack = dgc_isEnablePublish // 发布媒体
//        dgc_mediaOptions.publishMicrophoneTrack = dgc_isEnablePublish // 发布麦克风
        dgc_mediaOptions.publishMediaPlayerAudioTrack = false // 发布媒体
        dgc_mediaOptions.publishMicrophoneTrack = false // 发布麦克风
//        dgc_mediaOptions.clientRoleType = dgc_role
        dgc_mediaOptions.clientRoleType = .audience
        
        let dgc_connection = dgc_extData.dgc_connection
        dgc_connection.channelId = "\(roomId)"
        dgc_connection.localUid = UInt(dgc_userId*1000)

        self.dgc_channelExts[roomId] = dgc_extData
        
        DGCLog.debug("RTC---声网--ChannelExt--join--开始--roomId=\(roomId)--localUid=\(dgc_connection.localUid)--token=\(token)")
        
        let dgc_result = dgc_agoraKit?.joinChannelEx(byToken: token, dgc_connection: dgc_connection, delegate: dgc_channelExtDelegate, dgc_mediaOptions: dgc_mediaOptions, joinSuccess: {[weak self] channel, rUid, elapsed in
            DGCLog.debug("RTC---声网--ChannelExt--join成功")
            self?.delegate.rtcAdapterEnterRoomSuccessedWithResult(nil,roomId)
        }) ?? -1
        if dgc_result < 0 {//进入失败
            DGCLog.debug("RTC---声网--ChannelExt---join失败--dgc_result=\(dgc_result)")
        }
        // 开启声音回调
        dgc_agoraKit?.enableAudioVolumeIndicationEx(1000, smooth: 3, reportVad: false, dgc_connection: dgc_connection)
    }
    
    // 退出多频道
    func leaveChannelExt(roomId : Int64) {
        guard let dgc_extData = self.dgc_channelExts[roomId] else { return }
        let dgc_result = dgc_agoraKit?.leaveChannelEx(dgc_extData.connection, leaveChannelBlock: { stats in
            DGCLog.debug("RTC---声网--ChannelExt--leave--success")
        }) ?? -1
        
        self.dgc_channelExts[roomId] = nil
        
        if dgc_result < 0 {
            DGCLog.debug("RTC---声网--ChannelExt--leave--fail-dgc_result==\(dgc_result)")
        }
    }
    
    // 退出所有多频道
    func leaveChannelAllExt() {
        if dgc_channelExts.isEmpty{return}
        dgc_channelExts.forEach { (roomId,value) in
            self.leaveChannelExt(roomId: roomId)
        }
        dgc_channelExts.removeAll()
    }
    
    // 静音其他频道
    func openExtAudio(roomId: Int64, _ isMute: Bool) {
        guard let dgc_extData = self.dgc_channelExts[roomId] else { return }
        if dgc_extData.isMute == isMute {
            return
        }
        DGCLog.debug("RTC---声网--静音频道--isMute=\(isMute)--roomId=\(roomId)-\(dgc_extData.connection)")
        let dgc_result = dgc_agoraKit?.muteAllRemoteAudioStreamsEx(isMute, connection: dgc_extData.connection)
        if dgc_result == 0 {
            dgc_extData.isMute = isMute
            self.dgc_channelExts[roomId] = dgc_extData
        }
    }
    
    func setExtRemoteView(view: UIView, uId: Int64, roomId: Int64) {
        guard let dgc_extData = self.dgc_channelExts[roomId] else { return }
        let dgc_videoCanvas = AgoraRtcVideoCanvas()
        let dgc_tId = uId
        dgc_videoCanvas.uid = UInt(dgc_tId)
        dgc_videoCanvas.renderMode = .hidden
        dgc_videoCanvas.view = view
        let dgc_code = dgc_agoraKit?.setupRemoteVideoEx(dgc_videoCanvas, connection: dgc_extData.connection) ?? -999
        DGCLog.info("RTC---声网--ChannelExt-远端预览视图tId=\(dgc_tId)==\(roomId)====dgc_code:\(dgc_code)")
    }
}


extension DGCAgoraAdapter : AgoraVideoFrameDelegate{
    
    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        if dgc_effectService.isCanUse == false { // 不启用
            return true
        }
        guard let dgc_pixelBuffer = videoFrame.dgc_pixelBuffer else { return true }
//        dgc_beautyAPI.onFrame(dgc_pixelBuffer) { dgc_pixelBuffer in
//            videoFrame.dgc_pixelBuffer = dgc_pixelBuffer
//        }
        let dgc_rotation = videoFrame.dgc_rotation;
        let dgc_timeStamp = Double(videoFrame.renderTimeMs);
        
        let dgc_newPixelBuffer = dgc_effectService.process(with: dgc_pixelBuffer, dgc_rotation: dgc_rotation, dgc_timeStamp: dgc_timeStamp)
        
        videoFrame.dgc_pixelBuffer = dgc_newPixelBuffer.takeUnretainedValue()
        
        return true
    }
    
    // 必须设置 处理后赋值 videoFrame.pixelBuffer = newPixelBuffer.takeUnretainedValue() 才能生效
    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        .readWrite
    }
    
}

