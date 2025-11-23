import { ConsoleStdout, File, OpenFile, PreopenDirectory, WASI } from '@bjorn3/browser_wasi_shim';
import './style.css';
import nciUrl from './nci.wasm?url';

declare global {
  interface Uint8Array {
    toHex(): string;
  }
}

class ConsoleStdoutUnbuffered extends ConsoleStdout {
  #print: (buffer: string) => void;
  #decoder: TextDecoder;

  constructor(print: (buffer: string) => void) {
    const decoder = new TextDecoder('utf-8', { fatal: false });
    super(buf => {
      print(decoder.decode(buf, { stream: true }));
    });
    this.#print = print;
    this.#decoder = decoder;
  }

  flush(): void {
    this.#print(this.#decoder.decode(new Uint8Array([])));
  }
}

function clearOut(): void {
  stdoutElem.value = '';
  stdhexElem.value = '';
  stderrElem.value = '';
}

const codeElem = document.querySelector<HTMLTextAreaElement>('#code')!;
const stdinElem = document.querySelector<HTMLTextAreaElement>('#stdin')!;
const stdoutElem = document.querySelector<HTMLTextAreaElement>('#stdout')!;
const stdhexElem = document.querySelector<HTMLTextAreaElement>('#stdhex')!;
const stderrElem = document.querySelector<HTMLTextAreaElement>('#stderr')!;
const maxOutLengthElem = document.querySelector<HTMLInputElement>('#max-out-length')!;
const wasmPromise = WebAssembly.compileStreaming(fetch(nciUrl));

document.querySelector<HTMLButtonElement>('#run')!.addEventListener('click', async () => {
  const code = codeElem.value;
  const stdinText = stdinElem.value;

  let maxOutLength = maxOutLengthElem.valueAsNumber;
  if (!Number.isInteger(maxOutLength)) {
    maxOutLength = 65535;
  }

  clearOut();

  const fds = [
    new OpenFile(new File(new TextEncoder().encode(stdinText))),
    new ConsoleStdoutUnbuffered(msg => {
      stdoutElem.value = (stdoutElem.value + msg).substring(stdoutElem.value.length + msg.length - maxOutLength);
      stdhexElem.value = (new TextEncoder()).encode(stdoutElem.value).toHex();
    }),
    new ConsoleStdoutUnbuffered(msg => {
      stderrElem.value = (stderrElem.value + msg).substring(stderrElem.value.length + msg.length - maxOutLength);
    }),
    new PreopenDirectory('.', [['src.nc', new File(new TextEncoder().encode(code))]] as any),
  ];
  const wasi = new WASI(['nci', 'src.nc'], [], fds, { debug: false });
  const wasm = await wasmPromise;
  const inst = await WebAssembly.instantiate(wasm, { 'wasi_snapshot_preview1': wasi.wasiImport });
  try {
    wasi.start(inst as any);
  } finally {
    (fds[1] as ConsoleStdoutUnbuffered).flush();
    (fds[2] as ConsoleStdoutUnbuffered).flush();
  }
});

document.querySelector<HTMLButtonElement>('#clear-out')!.addEventListener('click', clearOut);
