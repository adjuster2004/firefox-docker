#!/bin/bash
# run-background.sh - запуск в фоновом режиме

set -e

echo "========================================"
echo "🦊 Запуск Firefox Hosts Editor (фоновый режим)"
echo "========================================"

# Проверяем DISPLAY
if [ -z "$DISPLAY" ]; then
    echo "❌ Ошибка: DISPLAY не установлен"
    echo "Установите: export DISPLAY=:0"
    exit 1
fi

echo "🔍 DISPLAY=$DISPLAY"

# Разрешаем доступ к X серверу
echo "🔓 Разрешение доступа к X серверу..."
xhost +local:docker > /dev/null 2>&1 || true
xhost + 127.0.0.1 > /dev/null 2>&1 || true

# Создаем структуру проекта
mkdir -p data/hosts
mkdir -p web

# Создаем начальный hosts файл если его нет
if [ ! -f "data/hosts/system" ]; then
    cat > "data/hosts/system" << 'EOF'
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback

# Docker Firefox Hosts Editor
# Редактируйте через: http://localhost:5000

# Примеры:
# 192.168.1.100	server.local
# 10.0.0.5	database.local
EOF
    echo "✅ Создан начальный hosts файл"
fi

# Создаем веб-интерфейс (если не создан)
if [ ! -f "web/index.html" ]; then
    echo "📁 Создаю веб-интерфейс..."
    mkdir -p web
    # (добавьте содержимое веб-файлов из предыдущих ответов)
fi

echo "🔨 Сборка Docker образа..."
docker build -t firefox-hosts-editor .

# Останавливаем старый контейнер если он запущен
echo "🧹 Очистка старого контейнера..."
docker stop firefox-hosts-editor 2>/dev/null || true
docker rm firefox-hosts-editor 2>/dev/null || true

# Проверяем порт 5000
echo "🔍 Проверка порта 5000..."
if lsof -i :5000 > /dev/null 2>&1; then
    echo "⚠️  Порт 5000 занят. Освобождаю..."
    sudo fuser -k 5000/tcp 2>/dev/null || true
    sleep 2
fi

echo "🚀 Запуск контейнера в фоновом режиме..."
docker run -d \
  --name firefox-hosts-editor \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -p 5000:5000 \
  -v "$(pwd)/data/hosts/system:/etc/hosts:rw" \
  --shm-size=2g \
  --privileged \
  firefox-hosts-editor

echo ""
echo "✅ Контейнер запущен в фоновом режиме!"
echo "🌐 Веб-интерфейс: http://localhost:5000"
echo "🦊 Firefox откроется автоматически"
echo ""
echo "📋 Команды управления:"
echo "   ./status.sh     - статус контейнера"
echo "   ./logs.sh       - просмотр логов"
echo "   ./stop.sh       - остановка контейнера"
echo "   ./restart.sh    - перезапуск контейнера"
echo "   ./exec.sh       - вход в контейнер"
echo ""
echo "💡 Чтобы остановить: ./stop.sh"
