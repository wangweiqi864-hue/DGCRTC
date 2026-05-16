//
//  DGCRTCProtocol.swift
//  VLDLive
//
//  Created by Pi0007-linwieyan on 2024/3/20.
//

import Foundation

public protocol DGCRTCDataSource : NSObjectProtocol {
    
    //获取当前用户ID
    func rtcManagerGetPlayerID() -> Int64
    //获取房间ID
    func rtcManagerGetCurrentRoomId() -> Int64
        
    func rtcManagerNewToken() -> String
        
    //判断用户是否能说话 在麦上且没被禁麦
    func rtcManagerIsCanSpeack() -> Bool
    
    func rtcManagerGetIsLive() -> Bool
    
    func rtcManagerGetAgoMode() -> Int32
    
    func isClosed4AINoisereduction() -> Bool
    
}

//回调代理
@objc public protocol DGCRTCDelegate {
    //回调说话状态
    func rtcManagerSpeakerStatus(_ volume : CGFloat,_ uId : Int64)
    
    /// 显示首帧画面回调
    func rtcManagerSpeaker(showFirstFrame uId : Int64)
    
    // 多频道说话状态
    func rtcManagerExtSpeakerStatus(_ volume : CGFloat,_ uId : Int64)
    
    //回调说话状态
    
    @objc optional func rtcManagerJoinRoomRst(_ isSuccess:Bool, _ roomId: Int64)
}

public protocol DGCRTCBackMusicDelete : AnyObject {
    /// 伴奏 播放完毕
    func rtcBackMusicFinishPlay(_ fPath: String?)
    /// 伴奏销毁
    func rtcBackMusicStop()
    /// 伴奏 是否启用伴奏 通知其他人
    func rtcBackMusicEnable(isEnable: Bool)
    /// 伴奏 获取音量
    func rtcBackMusicGetVolume() -> Int
    /// 伴奏播放进度回调
    func rtcBackMusicPositionChanged(postion: Int, total: Int)
}

extension DGCRTCDelegate{
    func rtcManagerSpeakerStatus(_ volume : CGFloat,_ uId : Int64){}
}
