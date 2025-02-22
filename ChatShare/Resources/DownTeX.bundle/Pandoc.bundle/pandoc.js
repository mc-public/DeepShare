import {
    WASI,
    OpenFile,
    File,
    ConsoleStdout,
    PreopenDirectory,
} from "./index.js";

function utility_arraybuffer_to_base64(arrayBuffer) {
    var base64    = '';
    var encodings = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  
    var bytes         = new Uint8Array(arrayBuffer);
    var byteLength    = bytes.byteLength;
    var byteRemainder = byteLength % 3;
    var mainLength    = byteLength - byteRemainder;
    var a, b, c, d;
    var chunk;
    for (var i = 0; i < mainLength; i = i + 3) {
      // Combine the three bytes into a single integer
      chunk = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
  
      // Use bitmasks to extract 6-bit segments from the triplet
      a = (chunk & 16515072) >> 18; // 16515072 = (2^6 - 1) << 18
      b = (chunk & 258048)   >> 12; // 258048   = (2^6 - 1) << 12
      c = (chunk & 4032)     >>  6; // 4032     = (2^6 - 1) << 6
      d = chunk & 63;               // 63       = 2^6 - 1
      base64 += encodings[a] + encodings[b] + encodings[c] + encodings[d];
    }
  
    // Deal with the remaining bytes and padding
    if (byteRemainder == 1) {
      chunk = bytes[mainLength];
  
      a = (chunk & 252) >> 2; // 252 = (2^6 - 1) << 2
  
      // Set the 4 least significant bits to zero
      b = (chunk & 3)   << 4; // 3   = 2^2 - 1
  
      base64 += encodings[a] + encodings[b] + '=='
    } else if (byteRemainder == 2) {
      chunk = (bytes[mainLength] << 8) | bytes[mainLength + 1];
      a = (chunk & 64512) >> 10; // 64512 = (2^6 - 1) << 10
      b = (chunk & 1008)  >>  4; // 1008  = (2^6 - 1) << 4
      // Set the 2 least significant bits to zero
      c = (chunk & 15)    <<  2; // 15    = 2^4 - 1
      base64 += encodings[a] + encodings[b] + encodings[c] + '=';
    }
    return base64;
}

class PandocWASI {
    #instance = null;
    #isInitialized = false;
    #argcPtr = null;
    #argv = null;
    #argvPtr = null;

    constructor() {
        this.args = ["pandoc.wasm", "+RTS", "-H64m", "-RTS"];
        this.env = [];
        this.options = { debug: false };

        this.inFile = new File(new Uint8Array(), { readonly: true });
        this.outFile = new File(new Uint8Array(), { readonly: false });

        this.fds = [
            new OpenFile(new File(new Uint8Array(), { readonly: true })),
            ConsoleStdout.lineBuffered(msg => console.log(`[WASI stdout] ${msg}`)),
            ConsoleStdout.lineBuffered(msg => console.warn(`[WASI stderr] ${msg}`)),
            new PreopenDirectory("/", [
                ["in", this.inFile],
                ["out", this.outFile],
            ]),
        ];
        this.wasi = new WASI(
            this.args,
            this.env,
            this.fds,
            this.options
        );
    }
    
    #memoryDataView() {
        return new DataView(this.#instance.exports.memory.buffer);
    }

    async initialize() {
        if (this.#isInitialized) return;

        const response = await fetch("./pandoc.wasm");
        const wasmBytes = await response.arrayBuffer();
        const { instance } = await WebAssembly.instantiate(
            wasmBytes,
            { wasi_snapshot_preview1: this.wasi.wasiImport }
        );

        this.#instance = instance;
        this.wasi.initialize(this.#instance);
        this.#instance.exports.__wasm_call_ctors();

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
    
    #convert(argsStr, input) {
        const argsPtr = this.#instance.exports.malloc(argsStr.length);
        new TextEncoder().encodeInto(
            argsStr,
            new Uint8Array(
                this.#instance.exports.memory.buffer,
                argsPtr,
                argsStr.length
            )
        );
        this.inFile.data = new TextEncoder().encode(input);
        this.#instance.exports.wasm_main(argsPtr, argsStr.length);
    }
    
    pandoc(argsStr, input) {
        this.#convert(argsStr, input);
        return new TextDecoder("utf-8", { fatal: true })
            .decode(this.outFile.data);
    }
    
    pandoc_docx(input) {
        this.#convert('-f markdown -t docx --sandbox', input);
        let result = utility_arraybuffer_to_base64(this.outFile.data);
        console.log(result);
        return result;
    }
}

const pandocInstance = new PandocWASI();
await pandocInstance.initialize();
export const wasi_constant = {
    pandoc: (pars, content) => {
        return pandocInstance.pandoc(pars, content);
    },
    pandoc_docx: (content) => {
        return pandocInstance.pandoc_docx(content);
    }
};

window.pandoc = wasi_constant.pandoc;
window.pandoc_docx = wasi_constant.pandoc_docx;
export default PandocWASI;
