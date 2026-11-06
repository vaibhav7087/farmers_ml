const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');
const root = path.resolve(process.argv[2] || 'build/web');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.css': 'text/css' };
http.createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    let file = path.resolve(root, '.' + pathname);
    if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(403); return res.end(); }
    if (file === root) file = path.join(root, 'index.html');
    let body;
    try { body = await fs.readFile(file); }
    catch { file = path.join(root, 'index.html'); body = await fs.readFile(file); }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    res.end(body);
  } catch { res.writeHead(500); res.end('Website build unavailable. Run flutter build web first.'); }
}).listen(3000, '127.0.0.1', () => console.log('Farmer app: http://localhost:3000'));
