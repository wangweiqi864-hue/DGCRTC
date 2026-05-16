//
//  DGCVolcengineRTCAdapter.swift
//  Pods
//
//  Created by Pi0007 on 2025/9/10.
//

import Foundation
import VolcEngineRTC
import MGLog

class DGCVolcengineRTCAdapter : NSObject, DGCRTCAdapterProtocol {
    
    private var dgc_rtcVideo: ByteRTCVideo?
    private var dgc_rtcRoom: ByteRTCRoom?
    private var dgc_userId : Int64 = 0
    
    var dataSource: DGCRTCAdapterDataSource
    var delegate: DGCRTCAAdapterDelegate
    
    
    init(dataSource : DGCRTCAdapterDataSource, delegate : DGCRTCAAdapterDelegate) {
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    // 伴奏播放器
    var currMusicPath : String?
    var backMusicPlayer: ByteRTCMediaPlayer?
    
//    00166dfef65ad986b0179192d4fJgAamCYFMSzxZjHP82YHADEwMDAwMDUHADEwMDAwMDUBAAQAAAAAACAA0RKk8nCzXiu9TNsKYAvM/wLdjlrvRZrACklmnrNuZe8=
    func setupSDK(appID: String, appKey: String) {
        self.dgc_rtcVideo = ByteRTCVideo.createRTCVideo(appID, delegate: self, parameters: [:])
        let dgc_config = ByteRTCAudioPropertiesConfig()
        dgc_config.interval = 500
        dgc_config.localMainReportMode = .disconnect
        dgc_config.audioReportMode = .audioMixing
        dgc_config.enableSpectrum = false
        dgc_config.enableVad = false
        dgc_config.enableVoicePitch = false
        self.dgc_rtcVideo?.enableAudioPropertiesReport(dgc_config)
        MGLog.info("RTC---火山-----------installSDK")
        backMusicPlayer = self.dgc_rtcVideo?.getMediaPlayer(0)
        backMusicPlayer?.setEventHandler(self)
    }
    
    func refreshSDK(appID: String, appKey: String) {
        let dgc_flag = dgc_rtcRoom?.updateToken(appKey) ?? -1
        MGLog.info("RTC---火山--刷新token==appID=\(appID)--appKey=\(appKey)--dgc_flag=\(dgc_flag)")
    }
    
    func setAudioSessionOperationRestriction(restriction: DGCAudioSessionOperationRestriction) {
        self.dgc_rtcVideo?.setAudioScene(.highQualityChatRoom) // 火山人员建议这样使用
    }
    
    func enablePublish(isEnablePublish: Bool) {
        MGLog.info("RTC---火山-isEnablePublish=\(isEnablePublish)")
        if isEnablePublish {
            self.dgc_rtcRoom?.setUserVisibility(true) // 流可见
        }else{
            self.dgc_rtcRoom?.setUserVisibility(false) // 流不可见
        }
        uploadLocalAudioStream()
        uploadLocalVideoStream()
    }
    
    func enableBackMusic(isEnableBackMusic: Bool) {
        uploadLocalAudioStream()
    }
    
    func uploadLocalAudioStream() {
        //麦克风是否可用  常用于在麦上的时候
        let dgc_isEnablePublish = delegate.rtcAdapterIsEnablePublish()
        if !dgc_isEnablePublish{ //不可用
            //都停掉
            setSpeakerVolume(0)
            let dgc_backMusicVolum : Int = delegate.rtcAdapterBackMusicVolum()
            setBackMusicVolume(volume: dgc_backMusicVolum)
//            self.dgc_rtcRoom?.setUserVisibility(false)
            // 关闭本地音频发送
            self.dgc_rtcVideo?.stopAudioCapture()
            self.dgc_rtcRoom?.unpublishStream(.audio)
            return
        }
        
        let dgc_isEnableBackMusic = delegate.rtcAdapterIsEnableBackMusic()
        if !dgc_isEnablePublish && !dgc_isEnableBackMusic{//都没开启 全部停止
//            self.dgc_rtcRoom?.setUserVisibility(false)
            self.dgc_rtcVideo?.stopAudioCapture()
            // 关闭本地音频发送
            self.dgc_rtcRoom?.unpublishStream(.audio)
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
            self.dgc_rtcVideo?.startAudioCapture()
            // 设置使用扬声器播放音频数据
            self.dgc_rtcVideo?.setDefaultAudioRoute(.speakerphone)
//            //启动流
//            self.dgc_rtcRoom?.setUserVisibility(true)
//            // 开启本地音频发送
            self.dgc_rtcRoom?.publishStream(.audio)
        }
    }
    
    func uploadLocalVideoStream() {
        //麦克风是否可用  常用于在麦上的时候
        let dgc_isEnablePublish = delegate.rtcAdapterIsEnablePublish()
        if !dgc_isEnablePublish{ //不可用
            // 关闭本地视频发送
            self.dgc_rtcVideo?.stopVideoCapture()
            self.dgc_rtcRoom?.unpublishStream(.video)
            return
        }
        let dgc_isEnableCamera = delegate.rtcAdapterIsEnableCamera()
        if dgc_isEnableCamera {
            self.dgc_rtcVideo?.startVideoCapture()
            self.dgc_rtcRoom?.publishStream(.video) // 发布本地流
        }else{
            self.dgc_rtcVideo?.stopVideoCapture()
            self.dgc_rtcRoom?.unpublishStream(.video) // 停止发布本地流
        }
    }
    
    func openRemoteAudio(_ isMute: Bool) {
        self.dgc_rtcVideo?.setPlaybackVolume(isMute ? 0 : 100)
    }
    
    func openMic(_ isOpen: Bool) {
        uploadLocalAudioStream()
    }
    
    func setSpeakerVolume(_ volume: Int) {
        if let dgc_index = ByteRTCStreamIndex(rawValue: 0){
            dgc_rtcVideo?.setCaptureVolume(dgc_index, volume: Int32(volume))
        }
    }
    
    func setSpeakerMute() {
        let dgc_isCanSpeaker = delegate.rtcAdapterIsOpenSpeaker()
        var dgc_volum : Int = delegate.rtcAdapterSpeakerVolum()
        if dgc_isCanSpeaker {
            dgc_volum = dgc_volum <= 0 ? 100 : dgc_volum
        }else{//关掉的时候 把麦克风设置成0
            dgc_volum = 0
        }
        setSpeakerVolume(dgc_volum)
    }
    
    func joinRoom() {
        let dgc_token = dataSource.adapterNewToken()
        let dgc_roomId = dataSource.adapterGetCurrentRoomId()
        let dgc_userId = dataSource.adapterGetPlayerID()
        if dgc_roomId <= 0 || dgc_userId <= 0 {
            MGLog.error("RTC---火山--SDK进房数据丢失")
            delegate.rtcAdapterEnterRoomFailedWithResult(DGCRTCAdapterResult(msg: "进房数据异常", code: -1))
            return
        }
        self.dgc_userId = dgc_userId
        // 加入房间
        self.dgc_rtcRoom = self.dgc_rtcVideo?.createRTCRoom("\(dgc_roomId)")
        self.dgc_rtcRoom?.delegate = self
        let dgc_userInfo = ByteRTCUserInfo.init()
        dgc_userInfo.dgc_userId = "\(dgc_userId)"
        let dgc_roomCfg = ByteRTCRoomConfig.init()
//        dgc_roomCfg.profile = .chatRoom
        dgc_roomCfg.isAutoPublish = false
        //    语聊房内语音 用了自动订阅模式，这样也导致了语聊房和游戏房内都重复订阅游戏音频流。
        //          要改成手动订阅 ，然后在  可以在onUserPublishStream回调里 判断不是 游戏流(user_id_for_pod) 就订阅.  https://www.volcengine.com/docs/6348/129241
        dgc_roomCfg.isAutoSubscribeAudio = false // 改成手动订阅, 因为火山弹幕游戏原因
        dgc_roomCfg.isAutoSubscribeVideo = false
        self.dgc_rtcRoom?.setUserVisibility(false) // 设置不可以见 上麦后设置为可见
        let dgc_result = self.dgc_rtcRoom?.joinRoom(dgc_token, userInfo: dgc_userInfo, roomConfig: dgc_roomCfg) ?? -1
        if dgc_result < 0 {//进入失败
            MGLog.debug("RTC---火山--进房失败...")
            delegate.rtcAdapterEnterRoomFailedWithResult(nil)
        }else{
            MGLog.info("RTC---火山--进房成功")
            delegate.rtcAdapterEnterRoomSuccessedWithResult(nil,dgc_roomId)
        }
    }
    
    func quitRoom(isDestroySDK: Bool) {
        let dgc_result = self.dgc_rtcRoom?.leaveRoom() ?? -1
        if dgc_result < 0 {
            MGLog.debug("RTC---火山--退房失败")
        }
        stopPreview(isDestroySDK: isDestroySDK)
        if isDestroySDK {
            self.dgc_userId = 0;
            if dgc_rtcRoom != nil {
                dgc_rtcRoom?.destroy()
                dgc_rtcRoom = nil
            }
            if dgc_rtcVideo != nil {
                ByteRTCVideo.destroyRTCVideo()
                dgc_rtcVideo = nil
            }
        }
    }
    
    func playBackMusic(musicPath: String, loop: Int) -> Int {
        let dgc_config = ByteRTCMediaPlayerConfig()
        dgc_config.playCount = loop
        dgc_config.type = .playoutAndPublish
        dgc_config.startPos = 0
//        dgc_config.startPos = startPos == 0 ? 1 : startPos // 注意: 火山RTC有bug, 所以穿1
        let dgc_code = backMusicPlayer?.open(musicPath, config: dgc_config) ?? -1
        if dgc_code == 0{
            currMusicPath = musicPath
        }else{
            currMusicPath = nil
        }
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    
    func pauseBackMusic() -> Int {
        let dgc_code = backMusicPlayer?.pause() ?? -1
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    
    func resumeBackMusic() -> Int {
        let dgc_code = backMusicPlayer?.resume() ?? -1
        uploadLocalAudioStream()
        return Int(dgc_code)
    }
    
    func stopBackMusic() -> Int {
        let dgc_code = backMusicPlayer?.stop() ?? -1
        uploadLocalAudioStream()
        currMusicPath = nil
        return Int(dgc_code)
    }
    
    @discardableResult
    func setBackMusicVolume(volume: Int) -> Int {
        var dgc_vl = Int32(volume)
        if (volume < 0) {dgc_vl = 0}
        if (volume > 100) {dgc_vl = 100}
        let dgc_code = backMusicPlayer?.setVolume(dgc_vl, type: .playoutAndPublish) ?? -1
        return Int(dgc_code)
    }
    
//    func getCurrentBackMusicVolume() -> Int {
//        return 0
//    }
    
    //设置伴奏进度 时间 单位ms
    func setBackMusicProgress(progress:Float) -> Int{
        guard let _ = currMusicPath else {
            return -999
        }
        var dgc_vl = progress
        if (progress < 0) {dgc_vl = 0}
        if (progress > 1) {dgc_vl = 1}
        let dgc_duration = backMusicPlayer?.getTotalDuration() ?? 0
        let dgc_posit = Int32(dgc_vl * Float(dgc_duration))
        let dgc_code = backMusicPlayer?.setPosition(dgc_posit) ?? 0
        return Int(dgc_code)
    }
    
    //获取当前伴奏的总时间 单位ms
    func getCurrentBackMusicDuration() -> Int {
        let dgc_duration = backMusicPlayer?.getTotalDuration() ?? 0
        return Int(dgc_duration)
    }
    
    //获取当前伴奏的播放时间 单位ms
    func getCurrentBackMusicCurrentPosition() -> Int {
        let dgc_duration = backMusicPlayer?.getPosition() ?? 0
        return Int(dgc_duration)
    }
    
    func stopPreview(isDestroySDK: Bool) {
        MGLog.info("RTC---火山-stopPreview")
        dgc_rtcVideo?.stopVideoCapture()
        if isDestroySDK {
            self.dgc_userId = 0;
            if dgc_rtcRoom != nil {
                dgc_rtcRoom?.destroy()
                dgc_rtcRoom = nil
            }
            if dgc_rtcVideo != nil {
                ByteRTCVideo.destroyRTCVideo()
                dgc_rtcVideo = nil
            }
        }
    }
    
    func setLocalView(view: UIView) {
        // 设置本地渲染视图
        let dgc_canvas = ByteRTCVideoCanvas.init()
        dgc_canvas.view = view
        dgc_canvas.renderMode = .hidden
        self.dgc_rtcVideo?.setLocalVideoCanvas(.indexMain, withCanvas: dgc_canvas)
    }

    func setRemoteView(view: UIView, uId: Int64) {
        // 设置远端用户视频渲染视图
        let dgc_canvas = ByteRTCVideoCanvas.init()
        dgc_canvas.view = view
        dgc_canvas.renderMode = .hidden
     
        let dgc_roomId = dataSource.adapterGetCurrentRoomId()
        let dgc_streamKey = ByteRTCRemoteStreamKey.init()
        dgc_streamKey.dgc_userId = "\(uId)";
        dgc_streamKey.roomId = "\(dgc_roomId)"
        dgc_streamKey.streamIndex = .indexMain
        let dgc_isFlag = self.dgc_rtcVideo?.setRemoteVideoCanvas(dgc_streamKey, withCanvas: dgc_canvas) ?? -1
        MGLog.info("RTC---火山-setRemoteView--uId=\(uId)-dgc_roomId=\(dgc_roomId)-dgc_isFlag=\(dgc_isFlag)")
    }
    
    func openCameraSwitch(_ isOpen: Bool) -> Bool {
        MGLog.info("RTC---火山-openCameraSwitch--isOpen=\(isOpen)")
        uploadLocalVideoStream()
        return true
    }
    
    func switchCamera(isFront: Bool) {
        MGLog.info("RTC---火山-switchCamera--isFront=\(isFront)")
        // {zh} 设置采集摄像头ID
        let dgc_cameraID : ByteRTCCameraID = isFront ? .front : .back
        self.dgc_rtcVideo?.switchCamera(dgc_cameraID)
    }
    
    func setLocalRenderMode(isMirror: Bool) {
        MGLog.info("RTC---火山-setLocalRenderMode--isMirror=\(isMirror)")
        
        dgc_rtcVideo?.setLocalVideoMirrorType(isMirror ? .renderAndEncoder : .none)
    }
    
    func enableVideo(isEnableVideo: Bool) {
        MGLog.info("RTC---火山-isEnableVideo=\(isEnableVideo)")
        if isEnableVideo {
            dgc_rtcRoom?.subscribeAllStreams(with: .video)
        }else{
            dgc_rtcRoom?.unpublishStream(.video)
            dgc_rtcRoom?.unsubscribeAllStreams(with: .video)
        }
        uploadLocalVideoStream()
    }
    
    private let dgc_videoConfig = ByteRTCVideoEncoderConfig()
    
    func setVideoEncodeConfig(config: DGCRTCManagerVideoEncodeConfig) {
        if config.size == .zero ||  (Int(config.size.width) == dgc_videoConfig.width && Int(config.size.height) == dgc_videoConfig.height) {
            return
        }
        // 设置视频编码参数
        dgc_videoConfig.width = Int(config.size.width)
        dgc_videoConfig.height = Int(config.size.height)
        dgc_videoConfig.frameRate = 15
//        dgc_videoConfig.maxBitrate = 1520; // 单位：kbs
        self.dgc_rtcVideo?.setMaxVideoEncoderConfig(dgc_videoConfig)
    }
    
    func enableSetBeauty(isSetBeauty: Bool) {
        
    }
    
    func enableAIAinsMode(isEnableAIAinsMode: Bool, mode: Int32) {
    
    }
    
    // 加入多频道
    // roomID 需要加入的房间ID
    // token 新频道的token
    func joinChannelExt(roomId: Int64, token: String) {}
    
    // 退出多频道
    func leaveChannelExt(roomId : Int64) {}
    
    // 退出所有多频道
    func leaveChannelAllExt() {}
    
    // 静音其他频道
    func openExtAudio(roomId: Int64, _ isMute: Bool) {}
    
    func setExtRemoteView(view: UIView, uId: Int64, roomId: Int64) {}
}


extension DGCVolcengineRTCAdapter : ByteRTCRoomDelegate{
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onUserJoined userInfo: ByteRTCUserInfo, elapsed: Int) {
        MGLog.info("RTC---火山--进入房间-userInfo=\(userInfo)")
    }
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onLeaveRoom stats: ByteRTCRoomStats) {
        MGLog.info("RTC---火山--离开房间")
    }
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onUserLeave uid: String, reason: ByteRTCUserOfflineReason) {
        MGLog.info("RTC---火山--离开房间1-uid=\(uid)-reason=\(reason)")
    }
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onRoomStateChanged roomId: String, withUid uid: String, state: Int, extraInfo: String) {
//        ByteRTCErrorCode
        MGLog.info("RTC---火山--房间状态-roomId=\(roomId)-uid=\(uid)-state=\(state)-extraInfo=\(extraInfo)")
    }
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onStreamStateChanged roomId: String, withUid uid: String, state: Int, extraInfo: String) {
        MGLog.info("RTC---火山--流变化-roomId=\(roomId)-uid=\(uid)-state=\(state)-extraInfo=\(extraInfo)")
    }
    
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onStreamSubscribed state: ByteRTCSubscribeState, userId: String, subscribeConfig info: ByteRTCSubscribeConfig) {
        MGLog.info("RTC---火山--流被订阅-state=\(state)-dgc_userId=\(dgc_userId)")
    }
    
}

extension DGCVolcengineRTCAdapter : ByteRTCVideoDelegate{
    
    func rtcEngine(_ engine: ByteRTCVideo, onConnectionStateChanged state: ByteRTCConnectionState) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onConnectionStateChanged: state)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onError errorCode: ByteRTCErrorCode) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onError: errorCode)
//            }
//        }
        MGLog.info("RTC---火山--error=\(errorCode)")
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onLocalAudioPropertiesReport audioPropertiesInfos: [ByteRTCLocalAudioPropertiesInfo]) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onLocalAudioPropertiesReport: audioPropertiesInfos)
//            }
//        }
        
        let dgc_isOpenSpeaker = delegate.rtcAdapterIsOpenSpeaker()
        if dgc_isOpenSpeaker == false {
            return
        }
        for speaker in audioPropertiesInfos {
            let dgc_vl = speaker.audioPropertiesInfo.linearVolume
            if dgc_vl <= 0 {
                continue
            }
            let dgc_uid = self.dgc_userId
            //计算当前音量
            let dgc_volume = CGFloat(dgc_vl) / 255.0
            if dgc_volume > 0 {
                //回调 说话状态
                if Thread.isMainThread{
                    delegate.rtcAdapterSpeakerStatus(dgc_volume, dgc_uid)
                }else{
                    DispatchQueue.main.async {
                        self.delegate.rtcAdapterSpeakerStatus(dgc_volume, dgc_uid)
                    }
                }
            }
        }
//        MGLog.info("RTC---火山--onLocalAudioPropertiesReport=")
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onRemoteAudioPropertiesReport audioPropertiesInfos: [ByteRTCRemoteAudioPropertiesInfo], totalRemoteVolume: Int) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onRemoteAudioPropertiesReport: audioPropertiesInfos, totalRemoteVolume: totalRemoteVolume)
//            }
//        }
        
        for speaker in audioPropertiesInfos {
            let dgc_vl = speaker.audioPropertiesInfo.linearVolume
            if dgc_vl <= 0 {
                continue
            }
            let dgc_streamKey = speaker.streamKey
            let dgc_uid = Int64(dgc_streamKey.dgc_userId ?? "") ?? 0
            //计算当前音量
            let dgc_volume = CGFloat(dgc_vl) / 255.0
            if dgc_volume > 0 {
                //回调 说话状态
                if Thread.isMainThread{
                    delegate.rtcAdapterSpeakerStatus(dgc_volume, dgc_uid)
                }else{
                    DispatchQueue.main.async {
                        self.delegate.rtcAdapterSpeakerStatus(dgc_volume, dgc_uid)
                    }
                }
            }
        }
//        MGLog.info("RTC---火山--onRemoteAudioPropertiesReport=")
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onWarning code: ByteRTCWarningCode) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onWarning: code)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onFirstRemoteAudioFrame key: ByteRTCRemoteStreamKey) {
        
        MGLog.info("RTC---火山--onFirstRemoteAudioFrame======roomId:\((key.roomId ?? ""))======userId:\((key.dgc_userId ?? ""))")
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onFirstRemoteAudioFrame: key)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onFirstRemoteVideoFrameDecoded streamKey: ByteRTCRemoteStreamKey, withFrameInfo frameInfo: ByteRTCVideoFrameInfo) {
        MGLog.info("RTC---火山--onFirstRemoteVideoFrameDecoded======roomId:\((streamKey.roomId ?? ""))======userId:\((streamKey.dgc_userId ?? ""))")
//        DispatchQueue.main.async {
//            if let dgc_mediaPlayer = self.mediaPlayer {
//                if let dgc_rtcVideoHandler = dgc_mediaPlayer.manager?.getRtcVideoHandler() {
//                    dgc_rtcVideoHandler.rtcEngine?(engine, onFirstRemoteVideoFrameDecoded: streamKey, withFrameInfo: frameInfo)
//                }
//                dgc_mediaPlayer.bindRemoteRenderView(roomId: (streamKey.roomId ?? ""), userId: (streamKey.dgc_userId ?? ""))
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onFirstRemoteVideoFrameRendered streamKey: ByteRTCRemoteStreamKey, withFrameInfo frameInfo: ByteRTCVideoFrameInfo) {
        MGLog.info("RTC---火山--onFirstRemoteVideoFrameRendered======roomId:\((streamKey.roomId ?? ""))======userId:\((streamKey.dgc_userId ?? ""))")
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onFirstRemoteVideoFrameRendered: streamKey, withFrameInfo: frameInfo)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onRemoteVideoSizeChanged streamKey: ByteRTCRemoteStreamKey, withFrameInfo frameInfo: ByteRTCVideoFrameInfo) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onRemoteVideoSizeChanged: streamKey, withFrameInfo: frameInfo)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onNetworkTypeChanged type: ByteRTCNetworkType) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onNetworkTypeChanged: type)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onSEIMessageReceived remoteStreamKey: ByteRTCRemoteStreamKey, andMessage message: Data) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onSEIMessageReceived: remoteStreamKey, andMessage: message)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onAudioRouteChanged device: ByteRTCAudioRoute) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onAudioRouteChanged: device)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onAudioDeviceStateChanged deviceID: String, device_type deviceType: ByteRTCAudioDeviceType, device_state deviceState: ByteRTCMediaDeviceState, device_error deviceError: ByteRTCMediaDeviceError) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onAudioDeviceStateChanged: deviceID, device_type: deviceType, device_state: deviceState, device_error: deviceError)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onFirstLocalVideoFrameCaptured streamIndex: ByteRTCStreamIndex, withFrameInfo frameInfo: ByteRTCVideoFrameInfo) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onFirstLocalVideoFrameCaptured: streamIndex, withFrameInfo: frameInfo)
//            }
//        }
    }
    
    func rtcEngine(_ engine: ByteRTCVideo, onVideoDeviceStateChanged deviceID: String, device_type deviceType: ByteRTCVideoDeviceType, device_state deviceState: ByteRTCMediaDeviceState, device_error deviceError: ByteRTCMediaDeviceError) {
//        DispatchQueue.main.async {
//            if let dgc_rtcVideoHandler = self.mediaPlayer?.manager?.getRtcVideoHandler() {
//                dgc_rtcVideoHandler.rtcEngine?(engine, onVideoDeviceStateChanged: deviceID, device_type: deviceType, device_state: deviceState, device_error: deviceError)
//            }
//        }
    }
    
    // 手动订阅音频流/视频流
    func dgc_rtcRoom(_ rtcRoom: ByteRTCRoom, onUserPublishStream userId: String, type: ByteRTCMediaStreamType) {
        self.dgc_rtcRoom?.subscribeStream(dgc_userId, mediaStreamType: type)
        MGLog.info("RTC---火山--onUserPublishStream======userId:\(dgc_userId)======type:\(type.rawValue)")
    }
}

extension DGCVolcengineRTCAdapter : ByteRTCMediaPlayerEventHandler  {
    
    func onMediaPlayerStateChanged(_ playerId: Int32, state: ByteRTCPlayerState, error: ByteRTCPlayerError) {
        //播放结束
        if state == .stopped {
            MGLog.debug("RTC---火山--伴奏--声网--播放结束")
            if Thread.isMainThread{
                delegate.rtcAdapterBackMusicFinished(self.currMusicPath)
            } else {
                DispatchQueue.main.async {
                    self.delegate.rtcAdapterBackMusicFinished(self.currMusicPath)
                }
            }
        }
    }
    
    func onMediaPlayerPlayingProgress(_ playerId: Int32, progress: Int64) {
        if playerId != dgc_userId { return }
        let dgc_total = backMusicPlayer?.getTotalDuration() ?? 0
        if Thread.isMainThread{
            delegate.rtcAdapterBackMusicPositionChanged(postion: Int(progress), total: Int(dgc_total))
        } else {
            DispatchQueue.main.async {
                self.delegate.rtcAdapterBackMusicPositionChanged(postion: Int(progress), total: Int(dgc_total))
            }
        }
    }
}
