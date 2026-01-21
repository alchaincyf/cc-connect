declare module 'qrcode-terminal' {
  interface Options {
    small?: boolean;
  }
  export function generate(
    text: string,
    options?: Options,
    callback?: (qrcode: string) => void
  ): void;
}
