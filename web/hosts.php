<?php
$hosts_file = '/etc/hosts';

// Определяем что нужно: данные или информация
$action = $_GET['action'] ?? '';

if ($action === 'info') {
    // Возвращаем информацию о файле
    header('Content-Type: application/json; charset=utf-8');

    $info = [
        'filename' => $hosts_file,
        'real_path' => realpath($hosts_file) ?: $hosts_file,
        'exists' => file_exists($hosts_file),
        'readable' => is_readable($hosts_file),
        'writable' => is_writable($hosts_file),
        'permissions' => file_exists($hosts_file) ? substr(sprintf('%o', fileperms($hosts_file)), -4) : '0000',
        'owner' => file_exists($hosts_file) ? (posix_getpwuid(fileowner($hosts_file))['name'] ?? 'unknown') : 'unknown',
        'php_user' => get_current_user(),
        'is_mounted' => true,
        'host_path' => '/data/hosts/system (на хосте)'
    ];

    echo json_encode($info);

} elseif ($action === 'fix') {
    // Исправление прав
    header('Content-Type: text/plain; charset=utf-8');

    echo "Исправление прав на $hosts_file\n";
    echo "===============================\n\n";

    $commands = [
        "chmod 666 $hosts_file",
        "chown www-data:www-data $hosts_file 2>/dev/null",
        "chmod 777 $hosts_file"
    ];

    foreach ($commands as $cmd) {
        echo "Выполняем: $cmd\n";
        exec($cmd . " 2>&1", $output, $return_code);
        if ($return_code === 0) {
            echo "✅ Успешно\n";
        } else {
            echo "❌ Ошибка: " . implode("\n", $output) . "\n";
        }
        echo "\n";
    }

    echo "Результат:\n";
    echo "Доступен для записи: " . (is_writable($hosts_file) ? '✅ Да' : '❌ Нет') . "\n";
    echo "Права: " . substr(sprintf('%o', fileperms($hosts_file)), -4) . "\n";

} else {
    // По умолчанию: возвращаем содержимое hosts файла
    header('Content-Type: text/plain; charset=utf-8');

    if (file_exists($hosts_file) && is_readable($hosts_file)) {
        // Читаем файл
        $content = file_get_contents($hosts_file);
        if ($content === false) {
            echo "# ОШИБКА: Не удалось прочитать файл\n";
            echo "# Путь: $hosts_file\n\n";
            echo "127.0.0.1\tlocalhost\n";
            echo "::1\t\tlocalhost ip6-localhost ip6-loopback\n";
        } else {
            echo $content;
        }
    } else {
        echo "# ВНИМАНИЕ: Файл недоступен\n";
        echo "# Путь в контейнере: $hosts_file\n";
        echo "# Путь на хосте: ./data/hosts/system\n";
        echo "# Проверьте монтирование: docker run ... -v \$(pwd)/data/hosts/system:/etc/hosts\n\n";
        echo "127.0.0.1\tlocalhost\n";
        echo "::1\t\tlocalhost ip6-localhost ip6-loopback\n";
    }
}
?>
