import {
    WASI,
    OpenFile,
    File,
    ConsoleStdout,
    PreopenDirectory,
} from "./index.js";

class PandocWASI {
    #instance = null;
    #isInitialized = false;
    #argcPtr = null;
    #argv = null;
    #argvPtr = null;

    constructor() {
        // 初始化固定参数
        this.args = ["pandoc.wasm", "+RTS", "-H64m", "-RTS"];
        this.env = [];
        this.options = { debug: false };

        // 初始化文件系统
        this.inFile = new File(new Uint8Array(), { readonly: true });
        this.outFile = new File(new Uint8Array(), { readonly: false });

        // 配置文件描述符
        this.fds = [
            new OpenFile(new File(new Uint8Array(), { readonly: true })),
            ConsoleStdout.lineBuffered(msg => console.log(`[WASI stdout] ${msg}`)),
            ConsoleStdout.lineBuffered(msg => console.warn(`[WASI stderr] ${msg}`)),
            new PreopenDirectory("/", [
                ["in", this.inFile],
                ["out", this.outFile],
            ]),
        ];

        // 初始化WASI实例
        this.wasi = new WASI(
            this.args,
            this.env,
            this.fds,
            this.options
        );
    }

    // 私有方法：获取内存视图
    #memoryDataView() {
        return new DataView(this.#instance.exports.memory.buffer);
    }

    // 异步初始化方法
    async initialize() {
        if (this.#isInitialized) return;

        // 加载并实例化WASM模块
        const response = await fetch("./pandoc.wasm");
        const wasmBytes = await response.arrayBuffer();
        const { instance } = await WebAssembly.instantiate(
            wasmBytes,
            { wasi_snapshot_preview1: this.wasi.wasiImport }
        );

        this.#instance = instance;
        this.wasi.initialize(this.#instance);
        this.#instance.exports.__wasm_call_ctors();

        // 初始化运行时参数
        this.#argcPtr = this.#instance.exports.malloc(4);
        this.#memoryDataView().setUint32(this.#argcPtr, this.args.length, true);

        this.#argv = this.#instance.exports.malloc(4 * (this.args.length + 1));
        for (let i = 0; i < this.args.length; ++i) {
            const argPtr = this.#instance.exports.malloc(this.args[i].length + 1);
            new TextEncoder().encodeInto(
                this.args[i],
                new Uint8Array(
                    this.#instance.exports.memory.buffer,
                    argPtr,
                    this.args[i].length
                )
            );
            this.#memoryDataView().setUint8(argPtr + this.args[i].length, 0);
            this.#memoryDataView().setUint32(
                this.#argv + 4 * i,
                argPtr,
                true
            );
        }
        this.#memoryDataView().setUint32(
            this.#argv + 4 * this.args.length,
            0,
            true
        );

        this.#argvPtr = this.#instance.exports.malloc(4);
        this.#memoryDataView().setUint32(this.#argvPtr, this.#argv, true);
        this.#instance.exports.hs_init_with_rtsopts(this.#argcPtr, this.#argvPtr);

        this.#isInitialized = true;
    }

    // 主转换方法
    pandoc(argsStr, input) {
        // 准备输入参数
        const argsPtr = this.#instance.exports.malloc(argsStr.length);
        new TextEncoder().encodeInto(
            argsStr,
            new Uint8Array(
                this.#instance.exports.memory.buffer,
                argsPtr,
                argsStr.length
            )
        );

        // 设置输入内容
        this.inFile.data = new TextEncoder().encode(input);

        // 执行转换
        this.#instance.exports.wasm_main(argsPtr, argsStr.length);

        // 获取并返回输出
        return new TextDecoder("utf-8", { fatal: true })
            .decode(this.outFile.data);
    }
}

const pandocInstance = new PandocWASI();
await pandocInstance.initialize();
export const wasi_constant = {
    pandoc: (pars, content) => {
        return pandocInstance.pandoc(pars, content);
    }
};

window.pandoc = wasi_constant.pandoc;
export default PandocWASI;
