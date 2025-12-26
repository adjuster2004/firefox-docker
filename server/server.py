#!/usr/bin/env python3
import http.server
import socketserver
import urllib.parse
import os

HOSTS_FILE = "/etc/hosts"

class HostsHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            # Главная страница с редактором
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()

            # Загружаем текущий hosts
            try:
                with open(HOSTS_FILE, 'r') as f:
                    hosts_content = f.read()
            except:
                hosts_content = "# Файл hosts\n127.0.0.1\tlocalhost\n"

            # Экранируем для HTML
            hosts_content = hosts_content.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

            html = f'''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hosts Editor</title>
    <style>
        body {{ font-family: Arial; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 5px; }}
        textarea {{ width: 100%; height: 400px; font-family: monospace; padding: 10px; }}
        button {{ padding: 10px 20px; margin: 5px; background: #007bff; color: white; border: none; border-radius: 3px; }}
        button:hover {{ background: #0056b3; }}
        .message {{ padding: 10px; margin: 10px 0; border-radius: 3px; }}
        .success {{ background: #d4edda; color: #155724; }}
        .error {{ background: #f8d7da; color: #721c24; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📝 Docker Hosts Editor</h1>
        <p>Редактирование файла <code>/etc/hosts</code> в Docker контейнере</p>

        <form method="POST" action="/save">
            <textarea name="hosts">{hosts_content}</textarea><br>
            <button type="submit">💾 Сохранить</button>
            <button type="button" onclick="location.reload()">🔄 Обновить</button>
            <button type="button" onclick="addExample()">➕ Пример</button>
        </form>

        <div id="message" class="message"></div>

        <div style="margin-top: 20px; padding: 10px; background: #e7f3ff; border-radius: 3px;">
            <strong>Информация:</strong><br>
            • Файл: <code>/etc/hosts</code><br>
            • Порт: 5000<br>
            • Доступ: <a href="http://localhost:5000" target="_blank">http://localhost:5000</a>
        </div>
    </div>

    <script>
        function addExample() {{
            document.querySelector('textarea[name="hosts"]').value += '\\n# Пример:\\n# 192.168.1.100   myserver.local   # Мой сервер';
        }}

        // Показываем сообщение из URL
        const urlParams = new URLSearchParams(window.location.search);
        const msg = urlParams.get('message');
        const type = urlParams.get('type');
        if (msg) {{
            const msgDiv = document.getElementById('message');
            msgDiv.textContent = decodeURIComponent(msg);
            msgDiv.className = 'message ' + (type || 'success');
        }}
    </script>
</body>
</html>'''
            self.wfile.write(html.encode('utf-8'))

        elif self.path == '/raw':
            # Сырой hosts файл
            try:
                with open(HOSTS_FILE, 'r') as f:
                    content = f.read()
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(content.encode('utf-8'))
            except Exception as e:
                self.send_error(500, str(e))

        else:
            self.send_error(404, "Not Found")

    def do_POST(self):
        if self.path == '/save':
            # Сохраняем hosts
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')

            # Парсим данные формы
            parsed = urllib.parse.parse_qs(post_data)
            hosts_content = parsed.get('hosts', [''])[0]

            try:
                # Сохраняем файл
                with open(HOSTS_FILE, 'w') as f:
                    f.write(hosts_content)

                # Редирект с сообщением об успехе
                self.send_response(303)
                self.send_header('Location', '/?message=' + urllib.parse.quote('Файл сохранен!') + '&type=success')
                self.end_headers()
            except Exception as e:
                # Редирект с сообщением об ошибке
                self.send_response(303)
                self.send_header('Location', '/?message=' + urllib.parse.quote(f'Ошибка: {e}') + '&type=error')
                self.end_headers()
        else:
            self.send_error(404, "Not Found")

if __name__ == '__main__':
    PORT = 5000
    print(f"🚀 Сервер запущен на http://0.0.0.0:{PORT}")
    print(f"📁 Редактирование файла: {HOSTS_FILE}")

    with socketserver.TCPServer(("0.0.0.0", PORT), HostsHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 Сервер остановлен")
