//
//  TeXEngine+Notification.swift
//
//
//  Created by 孟超 on 2023/10/2.
//

import Foundation

extension TeXEngine {
    
    /// 当引擎即将开始编译时发出的通知
    ///
    /// 此通知发送的对象为当前的引擎实例
    public static let engineWillStartCompile = Notification.Name("TeXEngineWillStartCompile")
    /// 当引擎已经完成了编译时发出的通知
    ///
    /// 此通知发送的对象为当前的引擎实例以及编译结果
    public static let engineDidEndCompile = Notification.Name("TeXEngineDidEndCompile")
    /// 当引擎崩溃时发出的通知
    ///
    /// 此通知发送的对象为当前的引擎实例
    public static let engineDidCrash = Notification.Name("TeXEngineDidCrash")
    /// 当引擎从崩溃中恢复完成时发出的通知
    ///
    /// 发送此通知时发送的对象为当前的引擎实例
    public static let engineDidRecoveredFromCrash = Notification.Name("TeXEngineDidRecoveredFromCrash")
    
}
