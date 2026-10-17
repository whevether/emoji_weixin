// Local transport regression fixtures derived from the client contract.
// No KLIPY credentials or live requests are used.
const http = require('http');
const gif = Buffer.from('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==', 'base64');
const item = title => ({ id: title, title, file: {
  sm: {gif: {url: 'https://example.invalid/preview.gif'}},
  hd: {gif: {url: 'https://example.invalid/original.gif'}}
}});
http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;
  const term = url.searchParams.get('q') || 'trending';
  if (path.startsWith('/api/v1/test-key/')) {
    if (term === 'http-error') {
      res.writeHead(503, {'Content-Type': 'text/html'});
      return res.end('<html>upstream unavailable</html>');
    }
    if (term === 'invalid-json') {
      res.writeHead(200, {'Content-Type': 'application/json'});
      return res.end('{broken');
    }
    if (term === 'slow') await new Promise(r => setTimeout(r, 300));
    res.writeHead(200, {'Content-Type': 'application/json'});
    return res.end(JSON.stringify({data: {data: [null, item(term)]}}));
  }
  if (path === '/media/gif') {
    res.writeHead(200, {'Content-Type': 'image/gif'}); return res.end(gif);
  }
  if (path === '/media/html') {
    res.writeHead(200, {'Content-Type': 'text/html'}); return res.end('<html>not media</html>');
  }
  if (path === '/media/large') {
    res.writeHead(200, {'Content-Type': 'image/gif', 'Content-Length': 1024});
    return res.end(Buffer.alloc(1024));
  }
  if (path === '/media/chunked') {
    res.writeHead(200, {'Content-Type': 'image/gif'});
    res.write(Buffer.alloc(100)); return res.end(Buffer.alloc(100));
  }
  if (path === '/media/slow-body') {
    res.writeHead(200, {'Content-Type': 'image/gif'}); res.write(gif.subarray(0, 6));
    return setTimeout(() => res.end(gif.subarray(6)), 300);
  }
  res.writeHead(501); res.end('Outside the client regression contract');
}).listen(process.env.PORT || 4500);
