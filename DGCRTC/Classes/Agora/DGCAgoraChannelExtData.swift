//
//  DGCAgoraChannelExtData.swift
//  Pods
//
//  Created by Pi0007 on 2025/4/7.
//

import Foundation
import AgoraRtcKit
import MGLog

class DGCAgoraChannelExtData {
    var connection = AgoraRtcConnection()
    var options = AgoraRtcChannelMediaOptions()
    var isMute = false // 是否静音对方
}

class DGCAgoraChannelExtDelegate: NSObject, AgoraRtcEngineDelegate {
    
    var delegate: DGCRTCAAdapterDelegate
    init(delegate: DGCRTCAAdapterDelegate) {
        self.delegate = delegate
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        MGLog.debug("RTC---声网--ChannelExt--warning: \(warningCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        MGLog.debug("RTC---声网--ChannelExt--error: \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        MGLog.debug("RTC---声网--ChannelExt--成功--uid: \(uid)--channel=\(channel)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        MGLog.debug("RTC---声网--ChannelExt--成功--didJoinedOfUid--uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        MGLog.debug("RTC---声网--ChannelExt--成功--didOfflineOfUid---uid: \(uid)")
    }
    
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        for speaker in speakers {
            let dgc_uid = speaker.uid
            // 计算当前音量
            let dgc_volume : CGFloat = CGFloat(speaker.volume) / 255.0 //* 100.0
            if dgc_volume > 0 {
                //回调 说话状态
                if Thread.isMainThread{
                    delegate.rtcAdapterExtSpeakerStatus(dgc_volume, Int64(dgc_uid))
                }else{
                    DispatchQueue.main.async {
                        self.delegate.rtcAdapterExtSpeakerStatus(dgc_volume, Int64(dgc_uid))
                    }
                }
            }
        }
    }
    
}
