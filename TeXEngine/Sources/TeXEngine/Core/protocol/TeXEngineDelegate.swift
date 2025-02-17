//
//  TeXEngineDelegate.swift
//
//
//  Created by 孟超 on 2024/2/11.
//

import Foundation

/// 某个具体的 TeX 引擎的代理所应当遵循的协议
@MainActor public protocol TeXEngineDelegate: AnyObject {
    /// 引擎内部产生终端输出（即控制台输出）时调用的方法
    ///
    /// - Parameter content: 引擎内部调用 `printf` 等方法输出到标准输出流产生的字符串。
    func outputToConsole(engine: TeXEngineProvider, content: String)
    /// 引擎内部更改了状态时调用的方法
    ///
    /// - Parameter oldState: 引擎原先的状态。
    /// - Parameter newState: 引擎更改后的新状态，其值与原先的状态不同。
    func engineDidChangeState(engine: TeXEngineProvider, from oldState: EngineState, to newState: EngineState)
    /// 引擎完成加载文件查询器时调用的方法
    ///
    /// 该方法在文件查询器加载失败时不会调用
    ///
    /// - Parameter querier: 完成加载操作的文件查询器。
    func engineDidLoadFileQuerier(engine: TeXEngineProvider, querier: TeXFileQuerier)
    /// 引擎在调用某个文件 `URL` 所对应的数据时调用的方法
    ///
    /// - Parameter url: 引擎调用的文件所对应的 `URL`。
    func engineLoadedData(from url: URL)
}
