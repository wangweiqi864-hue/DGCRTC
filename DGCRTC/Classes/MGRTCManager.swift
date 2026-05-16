//
//  DGCRTCManager.swift
//  VLDLive
//
//  Created by Pi0007-linwieyan on 2024/3/19.
//

import Foundation
import MGLog

public enum DGCRTCType {
    case NO
    case Agora
    case Tencent
    case volcengine
}

class DGCRTCSpeacker {
    
    var uId : Int64 = -1
    
    var isSpeaking : Bool{
        volume > 0
    }
    
    var volume : CGFloat = 0
    
    var currTime : CFAbsoluteTime = 0
    
    /// 直播预览视图
    weak var liveView : UIView?
    
    /// 是否显示首帧图
    var isShowFirstFrame : Bool = false
    
    var isExt = false
}

public struct DGCRTCKey {
    public var appId = String()
    public var key = String()
    public var type = DGCRTCType.NO
    
    public init() {}
}


internal func RTCLog(_ msg : String, file: String = #file){
    MGLog.log("RTC--\(msg)",file: file)
}

public struct DGCRTCManagerConfig {
    public var isOnline = false
    public var logDir = String() // 日志存储位置 --非线上模式下会输入rtc日志
    
    public init(isOnline: Bool = false, logDir: String = String()) {
        self.isOnline = isOnline
        self.logDir = logDir
    }
}

public struct DGCRTCManagerVideoEncodeConfig {
    public var size = CGSize.zero
//    public var bitRate = 0 // 码率
    
    public init(size: CoreFoundation.CGSize = CGSize.zero) {
        self.size = size
    }
}

open class DGCRTCManager : NSObject {
    
    public static let share = DGCRTCManager()
    
    // rtc的配置
    private var dgc_rtcConfig = DGCRTCManagerConfig()
    
    // 初始化配置
    public func initConfig(config : DGCRTCManagerConfig){
        dgc_rtcConfig = config
    }
    
    private let dgc_queue = DispatchQueue(label: "DGCRTCManager.dgc_queue")
    private let dgc_queueKey = DispatchSpecificKey<Int>()
    
    override init() {
        super.init()
        dgc_queue.setSpecific(key: dgc_queueKey, value: 200)
    }
    
    public var dataSource : DGCRTCDataSource?
    var delegates : DGCRTCWeakDelegates<DGCRTCDelegate> = DGCRTCWeakDelegates()
    public var backMusicDelete : DGCRTCBackMusicDelete?
    
    private var dgc_rtcKey = DGCRTCKey()
    
    private var dgc_speackers : [Int64 : DGCRTCSpeacker] = [:]
    private var dgc_soundTimer : DispatchSourceTimer?
    
    public func addDelegate(_ delegate : DGCRTCDelegate){
        
        delegates.addDelegate(delegate)
    }
    
    private var dgc_context : DGCRTCAdapterProtocol?
    func getContext() -> DGCRTCAdapterProtocol? {
        if let dgc_context = dgc_context {
            if dgc_rtcKey.type == .Agora , dgc_context is DGCAgoraAdapter {
                return dgc_context
            }else if dgc_rtcKey.type == .volcengine , dgc_context is DGCVolcengineRTCAdapter {
                return dgc_context
            }
        }
        var dgc_context : DGCRTCAdapterProtocol?
        if dgc_rtcKey.type == .Agora{
            dgc_context = DGCAgoraAdapter(dataSource:self,delegate: self)
        }else if dgc_rtcKey.type == .volcengine{
            dgc_context = DGCVolcengineRTCAdapter(dataSource: self, delegate: self)
        }
        dgc_context = dgc_context
        return dgc_context
    }
    var context: DGCRTCAdapterProtocol?{ getContext() }

    //是否打开了麦克风
    public internal(set) var isOpenMic : Bool = false
    
    //当前讲话的音量
    public internal(set) var volume : Int = 100
    
    //是否静音
    public internal(set) var isMute : Bool = false
    
    //自己被禁音 策略触发
    public internal(set) var isSpeakerMute = false
    
    //是否启动发布 本地流发布到远端 变为主播模式
    private var dgc_isEnablePublish : Bool = false
    {
        didSet{
            if dgc_isEnablePublish == false {//取消发布
                isOpenMic = false
                isOpenCamera = false
                isMirror = false
            }
        }
    }
    
    /// 是否正在设置美颜
    private var dgc_isSetBeauty : Bool = false
    
//    private var dgc_isEnableMic : Bool = false{
//        didSet{
//            if isEnableMic == false {//退出麦克风 关麦
//                isOpenMic = false
//            }
//        }
//    }
    
    /// 是否启用视频模块
//    public internal(set) var isEnableVideo : Bool = false
    // 是否打开摄像头 默认打开
    public internal(set) var isOpenCamera : Bool = false
    // 摄像头是否是前置
    public internal(set) var isCameraFront : Bool = true
    // 画面是否镜像
    public internal(set) var isMirror : Bool = false
    
    
    //是否可以使用伴奏
    private var dgc_isEnableBackMusic : Bool = false{
        didSet{
            if dgc_isEnablePublish{
                backMusicDelete?.rtcBackMusicEnable(isEnable: dgc_isEnableBackMusic)
//                backMusic.enableBackMusic(isEnable: dgc_isEnableBackMusic)
//                if self.dgc_isEnableBackMusic != dgc_isEnableBackMusic{
//                    backMusic.enableBackMusic(isEnable: dgc_isEnableBackMusic)
//                }
            }
        }
    }

    //伴奏相关
//    lazy var backMusic: MGBackMusicModel = {
//        MGBackMusicModel()
//    }()
    
    func enableBackMusic(dgc_isEnableBackMusic : Bool) {
        dgc_queue.async {
            if self.dgc_isEnableBackMusic == dgc_isEnableBackMusic {
                return
            }
            self.dgc_isEnableBackMusic = dgc_isEnableBackMusic
            RTCLog("enableBackMusic=\(dgc_isEnableBackMusic)")
            self.context?.enableBackMusic(dgc_isEnableBackMusic: dgc_isEnableBackMusic)
        }
    }
    
    //禁止说话 包括伴奏
    public func setSpeakerMute(isSpeakerMute : Bool) {
        dgc_queue.async {
            if isSpeakerMute == self.isSpeakerMute{
                return
            }
            self.isSpeakerMute = isSpeakerMute
            RTCLog("setSpeakerMute=\(isSpeakerMute)--dgc_isEnablePublish=\(self.dgc_isEnablePublish)")
            if self.dgc_isEnablePublish{ //麦克风都没有启用 不处理了
                self.context?.setSpeakerMute()
            }
        }
    }
    
    // 是否可以发布 流
    public func enablePublish(dgc_isEnablePublish : Bool) {
        dgc_callSyncInQueue{
            if self.dgc_isEnablePublish == dgc_isEnablePublish {
    //            context?.enablePublish(dgc_isEnablePublish: dgc_isEnablePublish)
                return
            }
            RTCLog("enablePublish=\(dgc_isEnablePublish)")
            self.dgc_isEnablePublish = dgc_isEnablePublish
            self.context?.enablePublish(dgc_isEnablePublish: dgc_isEnablePublish)
        }
    }
    
    /// 设置美颜
    public func enableSetBeauty(dgc_isSetBeauty : Bool){
        dgc_queue.async {
            if self.dgc_isSetBeauty == dgc_isSetBeauty{
    //            context?.enablePublish(dgc_isEnablePublish: dgc_isEnablePublish)
                return
            }
            self.dgc_isSetBeauty = dgc_isSetBeauty
            self.context?.enableSetBeauty(dgc_isSetBeauty: dgc_isSetBeauty)
        }
    }
    
    public func enableMic(isOpenMic: Bool) {
        dgc_callSyncInQueue {
            if self.isOpenMic == isOpenMic{
                return
            }
            RTCLog("enableMic=\(isOpenMic)")
            self.isOpenMic = isOpenMic
            self.context?.openMic(isOpenMic)
        }
//        enable(isEnableMic: isEnableMic, dgc_isEnableBackMusic: self.dgc_isEnableBackMusic, isOpenMic: isOpenMic)
    }
    
    //设置音量
    public func setSpeakerVolume(_ volume : Int) {
        dgc_queue.async {
            RTCLog("setSpeakerVolume=\(volume)")
            self.context?.setSpeakerVolume(volume)
            self.volume  = volume
        }
    }

    
    public func setAIAinsMode(isEnableAIAinsMode: Bool,mode:Int32) {
        DispatchQueue.main.async {
            self.context?.enableAIAinsMode(isEnableAIAinsMode: isEnableAIAinsMode,mode: mode)
        }
    }
    
    @discardableResult
    public func setupSDK(dgc_rtcKey : DGCRTCKey) -> Bool {
        dgc_queue.async {
            if dgc_rtcKey.type == .NO {
                RTCLog("sdk类型不支持,不安装声音引擎-sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
                return
            }else if dgc_rtcKey.type == .Tencent{
                RTCLog("sdk类型不支持,不安装声音引擎-sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
                return
            }
            // appId 必须不为空 都重新初始化 因为视频通话也会初始化
            if self.dgc_rtcKey.type == dgc_rtcKey.type , self.dgc_rtcKey.appId == dgc_rtcKey.appId , self.dgc_rtcKey.key == dgc_rtcKey.key{
                RTCLog("相同的sdk sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
                return
            }
            self.dgc_rtcKey = dgc_rtcKey
            
            RTCLog("开始安装sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
            
            self.context?.setupSDK(appID: dgc_rtcKey.appId, appKey: dgc_rtcKey.key)
          
        }
        return true
    }
  
    
    /// 刷新token
    public func refreshSDKToken(dgc_rtcKey : DGCRTCKey) {
        // appId 必须不为空 都重新初始化 因为视频通话也会初始化
        if self.dgc_rtcKey.type == dgc_rtcKey.type , self.dgc_rtcKey.appId == dgc_rtcKey.appId , self.dgc_rtcKey.key == dgc_rtcKey.key{
            RTCLog("refreshSDKToken--相同的--sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
            return
        }
        RTCLog("refreshSDKToken--sdkType=\(dgc_rtcKey.type) appID = \(dgc_rtcKey.appId) appKey=\(dgc_rtcKey.key)")
        self.dgc_rtcKey = dgc_rtcKey
        context?.refreshSDK(appID: dgc_rtcKey.appId, appKey: dgc_rtcKey.key)
    }
    
    public func setAudioSessionOperationRestriction(restriction: MGAudioSessionOperationRestriction) {
        dgc_queue.async {
            RTCLog("setAudioSessionOperationRestriction=\(restriction)")
            self.context?.setAudioSessionOperationRestriction(restriction: restriction)
        }
    }
    
    //开启/关闭麦克风
    
    //开始静音
    public func isMute(_ isMute : Bool) {
        dgc_callSyncInQueue {
            RTCLog("isMute=\(isMute)")
            self.context?.openRemoteAudio(isMute)
            self.isMute = isMute
        }
    }
    
    @discardableResult
    open func openMic(_ isOpen : Bool) -> Bool {
        dgc_callSyncInQueue{
            RTCLog("openMic=\(isOpen)")
            self.isOpenMic = isOpen
            self.context?.openMic(isOpen)
        }
        return true
    }
    
    // 静音其他频道
    public func openExtAudio(roomId: Int64, _ isMute: Bool){
        if self.isMute { // 自己静音了
            context?.openExtAudio(roomId: roomId, true)
        }else{
            context?.openExtAudio(roomId: roomId, isMute)
        }
    }
    
//    func enable(isEnableMic: Bool, dgc_isEnableBackMusic : Bool, isOpenMic:Bool){
//        if self.isEnableMic == isEnableMic, self.dgc_isEnableBackMusic == dgc_isEnableBackMusic, self.isOpenMic == isOpenMic  {
//            return
//        }
//        self.isOpenMic = isOpenMic
//        self.isEnableMic = isEnableMic
//        self.dgc_isEnableBackMusic = dgc_isEnableBackMusic
//        context?.enable(isEnableMic: isEnableMic, dgc_isEnableBackMusic: dgc_isEnableBackMusic, isOpenMic: isOpenMic)
//    }

    //进房
    public func enterRoom() {
        dgc_queue.async {
            //取消静音
            self.isSpeakerMute = false
            self.context?.joinRoom()
        }
    }
    ///退房
    /// isDestroySDK 是否销毁sdk
    public func exitRoom(isDestroySDK : Bool = true) {
        dgc_queue.async {
            self.dgc_stopSoundTimer()
            self.isMute(true)
            self.isSpeakerMute = false
            self.enablePublish(dgc_isEnablePublish: false)
//            self.backMusic.stop()
            self.backMusicDelete?.rtcBackMusicStop()
            self.isMute = false
            self.context?.quitRoom(isDestroySDK: isDestroySDK)
            if isDestroySDK {
                self.dgc_rtcKey = DGCRTCKey()
            }
        }
        
    }
    
    public func switchRoom() {
        dgc_queue.async {
            self.dgc_stopSoundTimer()
            self.isSpeakerMute = false
            self.dgc_speackers.removeAll()
//            self.backMusic.stop()
            self.backMusicDelete?.rtcBackMusicStop()
            self.context?.joinRoom()
        }
    }
    
    // 是否启用视频模块
    // 需要在 enterRoom 方法之后调用 否则远端流无法订阅
    public func enableVideo(isEnableVideo : Bool) {
//        if isEnableVideo == self.isEnableVideo {
//            return
//        }
//        self.isEnableVideo = isEnableVideo
        dgc_queue.async {
            self.context?.enableVideo(isEnableVideo: isEnableVideo)
        }
    }
    
    /// 获取是否显示了首帧视频  暂未实现
    public func getSpeackerFirstFrameStatus(_ uId : Int64) -> Bool {
//        dgc_callSyncInQueue {
//            let dgc_speacker = dgc_speackers[uId]
//            return dgc_speacker?.isShowFirstFrame ?? false
//        }
        return true
    }
    
}

// 多频道相关
extension DGCRTCManager {
    // 加入多频道
    // roomID 需要加入的房间ID
    // token 新频道的token
    public func joinChannelExt(roomId: Int64, token: String){
        context?.joinChannelExt(roomId: roomId, token: token)
    }
    
    // 退出多频道
    public func leaveChannelExt(roomId : Int64) {
        if roomId <= 0 {return}
        context?.leaveChannelExt(roomId: roomId)
    }
    
    // 退出所有多频道
    public func leaveChannelAllExt() {
        context?.leaveChannelAllExt()
    }
    
    public func setExtRemoteView(view: UIView, uId: Int64, roomId: Int64) {
        context?.setExtRemoteView(view: view, uId: uId, roomId: roomId)
    }
}

extension DGCRTCManager : DGCRTCAdapterDataSource {
    
    func adapterGetPlayerID() -> Int64 {
        dataSource?.rtcManagerGetPlayerID() ?? 0
    }
    
    func adapterGetCurrentRoomId() -> Int64 {
        dataSource?.rtcManagerGetCurrentRoomId() ?? 0
    }
    
    func adapterNewToken() -> String {
        dataSource?.rtcManagerNewToken() ?? ""
    }
    
    func agoMode() -> Int32 {
        dataSource?.rtcManagerGetAgoMode() ?? 0
    }
    
    func isClosed4AINoisereduction() -> Bool {
        dataSource?.isClosed4AINoisereduction() ?? false
    }
}


// 视频相关
extension DGCRTCManager {
    
    // 开播工具准备 开启
    public func startPreview(){
        dgc_queue.async {
            self.isOpenCamera = true
//            self.isOpenMic = true
            self.enableVideo(isEnableVideo: true)
            self.enablePublish(dgc_isEnablePublish: true)
        }
    }
    
    // 开播工具准备 结束
    // inRoom 当前是否在房间
    public func stopPreview(inRoom: Bool = false){
        dgc_queue.async {
            self.isOpenCamera = false
            self.isMirror = false
            if inRoom {
                return
            }
            self.isOpenMic = false
            self.enablePublish(dgc_isEnablePublish: false)
            self.context?.stopPreview(isDestroySDK: true)
            self.dgc_rtcKey = DGCRTCKey()
        }
    }
    
    public func setLocalView(view : UIView){
        dgc_queue.async {
            let dgc_speacker = self.getSpeacker(uId: 0)
            if dgc_speacker.liveView == view { // 同一个视图
                return
            }
            dgc_speacker.liveView = view
            self.context?.setLocalView(view: view)
        }
    }
    
    public func setRemoteView(view : UIView,uId : Int64){
        dgc_queue.async {
            let dgc_speacker = self.getSpeacker(uId: uId)
            if dgc_speacker.liveView == view { // 同一个视图
                return
            }
            dgc_speacker.liveView = view
            self.context?.setRemoteView(view: view, uId: uId)
        }
    }
    
    @discardableResult
    public func openCameraSwitch(_ isOpen : Bool) -> Bool{
        dgc_callSyncInQueue {
            if isOpen == self.isOpenCamera {
                return
            }
            // 禁止熄屏
//            UIApplication.shared.isIdleTimerDisabled = isOpen
            self.isOpenCamera = isOpen
            self.context?.openCameraSwitch(isOpen)
        }
        return true
    }
    
    // 切换摄像头
    public func switchCamera(isFront : Bool) {
        dgc_callSyncInQueue {
            if isFront == self.isCameraFront {
                return
            }
            self.isCameraFront = isFront
            self.context?.switchCamera(isFront: isFront)
        }
    }
    
    public func setLocalRenderMode(isMirror : Bool){
        dgc_callSyncInQueue {
            if self.isMirror == isMirror {
                return
            }
            self.isMirror = isMirror
            self.context?.setLocalRenderMode(isMirror: isMirror)
        }
    }
    
    /// 设置编码配置
    public func setVideoEncodeConfig(config : DGCRTCManagerVideoEncodeConfig){
        dgc_queue.async {
            self.context?.setVideoEncodeConfig(config: config)
        }
    }
    
    
}

extension DGCRTCManager : DGCRTCAAdapterDelegate {
    func rtcAdapterIsEnableSetBeauty() -> Bool {dgc_isSetBeauty}
    
    func rtcAdapterGetConfig() -> DGCRTCManagerConfig {dgc_rtcConfig}
    
    func rtcAdapterEnterRoomSuccessedWithResult(_ result: DGCRTCAdapterResult?, _ roomid: Int64) {
        DispatchQueue.main.async {
            for delegate in self.delegates.allObjects {
                delegate.rtcManagerJoinRoomRst?(true, roomid)
            }
        }
        dgc_startSoundTimer()
    }
    
    func rtcAdapterEnterRoomFailedWithResult(_ result: DGCRTCAdapterResult?) {
        dgc_stopSoundTimer()
    }
    
    func rtcAdapterDisConnect(_ result: DGCRTCAdapterResult?) {
        dgc_stopSoundTimer()
    }
    
    func getSpeacker(uId : Int64) -> DGCRTCSpeacker {
        var dgc_model = dgc_speackers[uId]
        if dgc_model == nil{
            dgc_model = DGCRTCSpeacker()
        }
        return dgc_model!
    }
    
    func rtcAdapterSpeakerStatus(_ volume: CGFloat, _ uId: Int64) {
//        RTCLog("声网--声音回调 uId=\(uId)-- volume = \(volume)")
        dgc_queue.async {
            var dgc_model : DGCRTCSpeacker?
            if volume > 0 {
                dgc_model = self.getSpeacker(uId: uId)
            }
     
            if let dgc_model = dgc_model {
                
                dgc_model.uId = uId
                dgc_model.volume = volume
                self.dgc_speackers[uId] = dgc_model
                if volume > 0 {
                    let dgc_cTime = CFAbsoluteTimeGetCurrent()
                    dgc_model.currTime = dgc_cTime
                }
                DispatchQueue.main.async {
                    for delegate in self.delegates.allObjects {
                        delegate.rtcManagerSpeakerStatus(volume, uId)
                    }
                }
            }
        }
    }
    
    func rtcAdapterExtSpeakerStatus(_ volume: CGFloat, _ uId: Int64) {
        if uId <= 0 { // 对方房间自己的音量回调 不处理
            return
        }
        dgc_queue.async {
            var dgc_model : DGCRTCSpeacker?
            if volume > 0 {
                dgc_model = self.getSpeacker(uId: uId)
            }
     
            if let dgc_model = dgc_model {
                
                dgc_model.uId = uId
                dgc_model.volume = volume
                dgc_model.isExt = true
                self.dgc_speackers[uId] = dgc_model
                if volume > 0 {
                    let dgc_cTime = CFAbsoluteTimeGetCurrent()
                    dgc_model.currTime = dgc_cTime
                }
                DispatchQueue.main.async {
                    for delegate in self.delegates.allObjects {
                        delegate.rtcManagerExtSpeakerStatus(volume, uId)
                    }
                }
            }
        }
    }
    
    func rtcAdapterSpeaker(showFirstFrame uId: Int64) {
        var dgc_model : DGCRTCSpeacker?
        if volume > 0 {
            dgc_model = getSpeacker(uId: uId)
        }
        dgc_model?.isShowFirstFrame = true
        for delegate in delegates.allObjects {
            delegate.rtcManagerSpeaker(showFirstFrame: uId)
        }
    }
    
    func rtcAdapterBackMusicFinished(_ fPath: String?) {
        backMusicDelete?.rtcBackMusicFinishPlay(fPath)
    }
    
    func rtcAdapterBackMusicPositionChanged(postion: Int, total: Int) {
        backMusicDelete?.rtcBackMusicPositionChanged(postion: postion, total: total)
    }
    
    func rtcAdapterIsEnableBackMusic() -> Bool {
        dgc_isEnableBackMusic
    }
    
    func rtcAdapterIsEnablePublish() -> Bool {
        dgc_isEnablePublish
    }
    
    func rtcAdapterIsEnableCamera() -> Bool {
        isOpenCamera
    }
    
    func rtcAdapterIsLive() -> Bool {
        dataSource?.rtcManagerGetIsLive() ?? false
    }
    
    func rtcAdapterIsOpenSpeaker() -> Bool {
        
        if isSpeakerMute {
            return false
        }//不能说话
        
        return isOpenMic
    }
    
    func rtcAdapterSpeakerVolum() -> Int {
        volume
    }
    
    func rtcAdapterBackMusicVolum() -> Int {
        if isSpeakerMute { //不能播放伴奏
            return 0
        }
        if dgc_isEnablePublish == false {
            return 0
        }
        return backMusicDelete?.rtcBackMusicGetVolume() ?? 0
    }
    
    func rtcAdapterIsMirror() -> Bool { isMirror }
    func rtcAdapterIsCameraFront() -> Bool {isCameraFront}
}


// ----伴奏相关
extension DGCRTCManager {
    //播放伴奏 loop循环次数 -1无限循环
    @discardableResult
    public func playBackMusic(musicPath:String, loop:Int) -> Int{
        let dgc_code = context?.playBackMusic(musicPath: musicPath, loop: loop)
        enableBackMusic(dgc_isEnableBackMusic: true)
        return dgc_code ?? -1
    }
    
    //暂停伴奏
    @discardableResult
    public func pauseBackMusic() -> Int{
        let dgc_code = context?.pauseBackMusic()
        enableBackMusic(dgc_isEnableBackMusic: false)
        return dgc_code ?? -1
    }
    
    //恢复伴奏
    @discardableResult
    public func resumeBackMusic() -> Int{
        let dgc_code = context?.resumeBackMusic()
        enableBackMusic(dgc_isEnableBackMusic: true)
        return dgc_code ?? -1
    }
    
    //停止伴奏
    @discardableResult
    public func stopBackMusic() -> Int{
        let dgc_code = context?.stopBackMusic()
        enableBackMusic(dgc_isEnableBackMusic: false)
        return dgc_code ?? -1
    }
    
    //设置伴奏音量
    @discardableResult
    public func setBackMusicVolume(volume:Int) -> Int{
        let dgc_vl = rtcAdapterBackMusicVolum()
        let dgc_code = context?.setBackMusicVolume(volume: dgc_vl)
        return dgc_code ?? -1
    }
    
    //获取当前伴奏音量
//    @discardableResult
//    public func getCurrentBackMusicVolume() -> Int{
//        return context?.getCurrentBackMusicVolume()
//        return backMusicDelete?.rtcBackMusicGetVolume() ?? 0
//    }
    
    //设置伴奏进度 时间 单位ms
    @discardableResult
    public func setBackMusicProgress(progress:Float) -> Int{
        context?.setBackMusicProgress(progress: progress) ?? -1
    }
        
}



extension DGCRTCManager {
    
    private func dgc_startSoundTimer() {
        dgc_stopSoundTimer()
        
        // 创建一个定时器
        let dgc_timer = DispatchSource.makeTimerSource(dgc_queue: dgc_queue)
        
        // 设置定时器的参数
        let dgc_interval = DispatchTimeInterval.milliseconds(500)  // 0.5 触发一次
        let dgc_leeway = DispatchTimeInterval.milliseconds(100)  // 允许的误差范围为100毫秒
        dgc_timer.schedule(deadline: .now(), repeating: dgc_interval, leeway: dgc_leeway)
        // 定时器触发时执行的操作
        dgc_timer.setEventHandler {[weak self] in
            self?.dgc_soundTimerTick()
        }
        dgc_timer.resume()
        self.dgc_soundTimer = dgc_timer
        
    }
    
    //判断用户是否说话的状态
    @objc private func dgc_soundTimerTick() {
        for item in dgc_speackers.values {
            if item.isSpeaking {//正在讲话
                let dgc_cTime = CFAbsoluteTimeGetCurrent()
                let dgc_detail = dgc_cTime - item.currTime
                if dgc_detail > 1.0 {//超过1秒 没有说话隐藏
                    item.volume = 0
                    for delegate in delegates.allObjects {
//                        if item.isExt{
//                            delegate.voiceManagerSpeakerExtStatus(0, item.uId)
//                        }else{
//                            delegate.voiceManagerSpeakerStatus(0, item.uId)
//                        }
                        if Thread.isMainThread {
                            delegate.rtcManagerSpeakerStatus(0, item.uId)
                        }else{
                            DispatchQueue.main.async {
                                delegate.rtcManagerSpeakerStatus(0, item.uId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func dgc_stopSoundTimer() {
        dgc_speackers.removeAll()
        if dgc_soundTimer != nil {
            dgc_soundTimer?.cancel()
            dgc_soundTimer = nil
        }
    }
    
    
    // 同步处理，在同个队列
    private func dgc_callSyncInQueue(block :@escaping (()->Void)) {
        if DispatchQueue.getSpecific(key: dgc_queueKey) == 200 {
//            MGLog.log("RTC---声网--dgc_callSyncInQueue--thread=\(Thread.current)")
            block()
        }else{
            dgc_queue.sync{
//                MGLog.log("RTC---声网--dgc_callSyncInQueue----11")
                block()
            }
        }
    }
    
}
