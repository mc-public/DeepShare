//
//  EngineState.swift
//
//
//  Created by 孟超 on 2024/2/5.
//

import Foundation

/// 引擎的当前状态
public enum EngineState {
    /// 引擎未工作且未加载文件查询服务与引擎内核
    ///
    /// 此时引擎虽然已经被初始化，还未加载文件查询服务与引擎内核。需要确保加载文件查询服务后再调用编译相关的方法。
    case inited
    /// 引擎正在加载文件查询服务中
    ///
    /// 如果引擎处于此状态，则当前引擎在稍后会初始化或者重新加载引擎内核。此时不能调用任何编译相关的方法。
    case loadingFileQuerier
    /// 引擎已准备好进行编译
    ///
    /// 成功加载引擎内核后，引擎即改变为此状态。此时可以调用编译的相关方法。
    case ready
    /// 引擎正在加载引擎内核
    ///
    /// 如果引擎处于此状态，则当前引擎一定已经加载了文件查询服务。此时不能调用任何编译相关的方法。
    case loadingEngineCore
    /// 引擎正在执行编译操作
    ///
    /// 此时不能调用任何编译相关的方法。
    case compiling
    /// 引擎内核处于崩溃状态
    ///
    /// 此时不能调用任何编译相关的方法，使用本类的客户端必须手动清理引擎。
    case crashed
    
    /// 引擎是否正在工作中
    public var isWorking: Bool {
        self == .loadingEngineCore || self == .compiling || self == .loadingFileQuerier
    }
    
    /// 引擎是否已经加载了文件查询服务
    public var isLoadedFileQuerier: Bool {
        !(self == .inited || self == .loadingFileQuerier)
    }
}


