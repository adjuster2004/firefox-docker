<?php
// Скрипт для исправления прав доступа
$hosts_file = '/etc/hosts';

header('Content-Type: text/plain; charset=utf-8');

echo "Исправление прав на $hosts_file\n";
echo "================================\n";

// Текущие права
$perms = substr(sprintf('%o', fileperms($hosts_file)), -4);
echo "Текущие права: $perms\n";

// Пробуем исправить права
$commands = [
    "chmod 666 $hosts_file",
    "chown www-data:www-data $hosts_file",
    "chmod 777 $hosts_file"
];

foreach ($commands as $cmd) {
    echo "\nВыполняем: $cmd\n";
    exec($cmd . " 2>&1", $output, $return_code);

    if ($return_code === 0) {
        echo "✅ Успешно\n";
    } else {
        echo "❌ Ошибка: " . implode("\n", $output) . "\n";
    }
}

// Проверяем результат
echo "\nПроверка результата:\n";
echo "Файл существует: " . (file_exists($hosts_file) ? '✅ Да' : '❌ Нет') . "\n";
echo "Доступен для чтения: " . (is_readable($hosts_file) ? '✅ Да' : '❌ Нет') . "\n";
echo "Доступен для записи: " . (is_writable($hosts_file) ? '✅ Да' : '❌ Нет') . "\n";
echo "Новые права: " . substr(sprintf('%o', fileperms($hosts_file)), -4) . "\n";
echo "Владелец: " . (posix_getpwuid(fileowner($hosts_file))['name'] ?? 'unknown') . "\n";

if (is_writable($hosts_file)) {
    echo "\n🎉 Файл теперь доступен для записи!";
} else {
    echo "\n⚠️  Файл все еще недоступен для записи. Запустите контейнер с флагом --privileged";
}
?>
