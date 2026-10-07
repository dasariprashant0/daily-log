// Builds ONE self-contained ../app/Resources/editor/index.html (inline CSS + inline JS), no other file.
// The CSP <meta> carries the sha256 of the inline script, so no 'self'/file: origin rules are needed (WKWebView's
// CSP 'self' is unreliable for file: and custom schemes). Run: npm run build   (add --analyze for a size breakdown)
import { build } from 'esbuild'
import { createHash } from 'node:crypto'
import { mkdir, writeFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
export const OUT_FILE = resolve(here, '../app/Resources/editor/index.html')

export function bundle() {
  return build({
    entryPoints: [resolve(here, 'src/main.js')],
    outdir: resolve(here, 'out'), // never written (write:false); only names the css output
    write: false,
    bundle: true,
    minify: true,
    format: 'iife',
    platform: 'browser',
    target: ['safari16'], // macOS 13 WKWebView
    legalComments: 'none', // licences are listed in THIRD_PARTY_LICENSES.md
    metafile: true,
    logLevel: 'warning',
    define: {
      'process.env.NODE_ENV': '"production"',
      __VUE_OPTIONS_API__: 'false',
      __VUE_PROD_DEVTOOLS__: 'false',
      __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false'
    }
  })
}

export function page(js, css) {
  if (/<\/script/i.test(js)) throw new Error('bundle contains "</script": cannot be inlined safely')
  if (/<\/style/i.test(css)) throw new Error('bundle contains "</style": cannot be inlined safely')
  const hash = createHash('sha256').update(js, 'utf8').digest('base64')
  const csp = [
    "default-src 'none'",
    `script-src 'sha256-${hash}'`,
    "style-src 'unsafe-inline'",
    'img-src dlasset: data: blob:',
    'font-src data:',
    "connect-src 'none'",
    "form-action 'none'",
    "base-uri 'none'"
  ].join('; ')
  return {
    hash,
    html:
      '<!doctype html>\n' +
      '<html lang="en" data-theme="light">\n' +
      '<head>\n' +
      '<meta charset="utf-8">\n' +
      `<meta http-equiv="Content-Security-Policy" content="${csp}">\n` +
      '<meta name="viewport" content="width=device-width, initial-scale=1">\n' +
      '<meta name="color-scheme" content="light dark">\n' +
      '<title>Gloamlog editor</title>\n' +
      `<style>${css}</style>\n` +
      '</head>\n' +
      '<body>\n' +
      '<div id="app"></div>\n' +
      `<script>${js}</script>\n` +
      '</body>\n' +
      '</html>\n'
  }
}

async function main() {
  const result = await bundle()
  const js = result.outputFiles.find((f) => f.path.endsWith('.js')).text
  const css = result.outputFiles.find((f) => f.path.endsWith('.css')).text
  const { html, hash } = page(js, css)
  await mkdir(dirname(OUT_FILE), { recursive: true })
  await writeFile(OUT_FILE, html)

  const kb = (n) => (n / 1024).toFixed(1) + ' KB'
  console.log(`wrote ${OUT_FILE}`)
  console.log(`  js ${kb(js.length)}  css ${kb(css.length)}  html ${kb(Buffer.byteLength(html))}`)
  console.log(`  script sha256-${hash}`)

  if (process.argv.includes('--analyze')) {
    const byPkg = {}
    for (const o of Object.values(result.metafile.outputs)) {
      for (const [file, v] of Object.entries(o.inputs)) {
        const m = file.match(/node_modules\/((?:@[^/]+\/)?[^/]+)(?!.*node_modules)/)
        const key = m ? m[1] : '(project)'
        byPkg[key] = (byPkg[key] || 0) + v.bytesInOutput
      }
    }
    for (const [k, v] of Object.entries(byPkg).sort((a, b) => b[1] - a[1]).slice(0, 30)) {
      console.log(`  ${kb(v).padStart(10)}  ${k}`)
    }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main()
