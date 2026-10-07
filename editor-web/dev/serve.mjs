// Tiny static server for the dev harness and the fixture test page. No dependencies, no cache, localhost only.
//   node dev/serve.mjs            -> http://127.0.0.1:8137/editor-web/dev/   and   /editor-web/test/
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { extname, join, normalize, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(fileURLToPath(new URL('../..', import.meta.url))) // repo root
const port = Number(process.env.PORT) || 8137
const allowed = ['/app/Resources/editor/', '/editor-web/dev/', '/editor-web/test/']
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png'
}

createServer(async (req, res) => {
  let path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname)
  if (path.endsWith('/')) path += 'index.html'
  const file = normalize(join(root, path))
  if (!file.startsWith(root) || !allowed.some((p) => path.startsWith(p))) {
    res.writeHead(404).end('not found')
    return
  }
  try {
    const body = await readFile(file)
    res.writeHead(200, { 'content-type': types[extname(file)] || 'application/octet-stream', 'cache-control': 'no-store' })
    res.end(body)
  } catch {
    res.writeHead(404).end('not found')
  }
}).listen(port, '127.0.0.1', () => console.log(`http://127.0.0.1:${port}/editor-web/dev/  and  /editor-web/test/`))
