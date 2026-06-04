from http.server import HTTPServer, SimpleHTTPRequestHandler

PORT = 8080


class CustomHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>Hello from folder two!</h1>")


if __name__ == "__main__":
    server = HTTPServer(("", PORT), CustomHandler)
    print(f"Server running on port {PORT}")
    server.serve_forever()
