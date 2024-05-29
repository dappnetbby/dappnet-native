import http.server
import socketserver
import signal

PORT = 8087

class HttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        '': 'application/octet-stream',
        '.manifest': 'text/cache-manifest',
        '.html': 'text/html',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.svg':	'image/svg+xml',
        '.css':	'text/css',
        '.js':'application/x-javascript',
        '.wasm': 'application/wasm',
        '.json': 'application/json',
        '.xml': 'application/xml',
    }

    def translate_path(self, path):
        host = self.headers.get('Host')
        # base_paths = {
        #     'example.com': '/path1',
        #     'another-example.com': '/path2'
        # }
        # base_path = base_paths.get(host, '/')
        base_path = '/Users/liamz/Downloads/dappnet-native/tmp/ipfs-apps/bafybeifzk2sizlcd6xiowyo6xzktbwl4sadwedxwau53umuyzgjy2y5h4y'
        
        # Handle requests for the root path, or sub paths which are folders
        if path == '/':
            path = '/index.html'
        elif path.endswith('/'):
            path += 'index.html'
        
        # Add the base path.
        longpath = base_path + path
        
        # Strip the query string
        longpath = longpath.split('?')[0]

        print(longpath)
        return longpath

def sigint_handler(sig, frame):
    print('Ctrl+C received, closing server...')
    httpd.server_close()

signal.signal(signal.SIGINT, sigint_handler)

httpd = socketserver.TCPServer(("localhost", PORT), HttpRequestHandler)

try:
    print(f"serving at http://localhost:{PORT}")
    httpd.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    httpd.server_close()