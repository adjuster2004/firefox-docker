FROM debian:bookworm-slim

# Устанавливаем Apache, PHP и Firefox
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    php \
    firefox-esr \
    curl \
    libgtk-3-0 \
    libx11-xcb1 \
    libdbus-1-3 \
    libxt6 \
    libasound2 \
    ca-certificates \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Включаем mod_rewrite и настраиваем Apache
RUN a2enmod rewrite && \
    a2enmod php$(php -v | head -n1 | cut -d" " -f2 | cut -d"." -f1-2) && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    sed -i 's/Listen 80/Listen 5000/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:5000>/g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf && \
    rm -rf /var/www/html/*

# Создаем пользователя
RUN useradd -m -u 1000 firefox

# Копируем веб-файлы
COPY web/ /var/www/html/

# Настраиваем права - даем доступ к .htaccess
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod 644 /var/www/html/.htaccess

# Создаем скрипт запуска с исправлением прав
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🚀 Запуск Docker Hosts Editor..."\n\
\n\
# КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Даем права на запись в /etc/hosts\n\
echo "🔧 Исправление прав на /etc/hosts..."\n\
chmod 666 /etc/hosts\n\
chown www-data:www-data /etc/hosts 2>/dev/null || true\n\
\n\
# Проверяем права\n\
echo "📋 Текущие права /etc/hosts:"\n\
ls -la /etc/hosts\n\
\n\
# Убиваем старые процессы Firefox\n\
pkill -9 firefox 2>/dev/null || true\n\
\n\
# Создаем временный профиль Firefox\n\
PROFILE_DIR="/tmp/firefox-profile-$(id -u)"\n\
rm -rf "$PROFILE_DIR"\n\
mkdir -p "$PROFILE_DIR"\n\
\n\
# Создаем user.js для отключения проверок\n\
cat > "$PROFILE_DIR/user.js" << "EOF2"\n\
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);\n\
user_pref("datareporting.policy.firstRunURL", "");\n\
user_pref("browser.shell.checkDefaultBrowser", false);\n\
user_pref("browser.sessionstore.resume_from_crash", false);\n\
user_pref("browser.disableResetPrompt", true);\n\
user_pref("devtools.errorconsole.enabled", true);\n\
user_pref("browser.startup.homepage", "http://localhost:5000");\n\
user_pref("browser.startup.page", 1);\n\
EOF2\n\
\n\
# Запускаем Apache\n\
echo "🌐 Запуск Apache на порту 5000..."\n\
apache2ctl start\n\
\n\
# Ждем запуска Apache\n\
sleep 3\n\
\n\
# Проверяем доступность веб-интерфейса\n\
echo "🔍 Проверка веб-интерфейса..."\n\
if curl -s http://localhost:5000 | grep -q "Docker Hosts Editor"; then\n\
    echo "✅ Веб-интерфейс доступен"\n\
else\n\
    echo "⚠️  Проблема с веб-интерфейсом"\n\
    echo "Проверяем файлы:"\n\
    ls -la /var/www/html/\n\
fi\n\
\n\
# Запускаем Firefox\n\
echo "🦊 Запуск Firefox..."\n\
echo "DISPLAY: $DISPLAY"\n\
\n\
exec firefox-esr \\\n\
  --no-remote \\\n\
  --new-instance \\\n\
  --profile "$PROFILE_DIR" \\\n\
  "http://localhost:5000"\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 5000

CMD ["/start.sh"]
