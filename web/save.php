<?php
header('Content-Type: text/plain; charset=utf-8');

$hosts_file = '/etc/hosts';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $content = $_POST['hosts'] ?? '';

    if (empty($content)) {
        http_response_code(400);
        echo "ERROR: Пустой контент";
        exit;
    }

    echo "🔄 Сохранение файла...\n";
    echo "Путь: $hosts_file\n";
    echo "Реальный путь: " . (realpath($hosts_file) ?: $hosts_file) . "\n";
    echo "Размер контента: " . strlen($content) . " байт\n\n";

    // Пробуем сохранить несколькими методами
    $success = false;
    $error_message = '';

    // Метод 1: Прямая запись
    if (is_writable($hosts_file)) {
        $result = file_put_contents($hosts_file, $content);
        if ($result !== false) {
            $success = true;
            echo "✅ Сохранено напрямую\n";
            echo "Записано байт: $result\n";
        } else {
            $error_message = "Ошибка прямой записи";
        }
    } else {
        $error_message = "Файл недоступен для записи";
    }

    // Метод 2: Через временный файл
    if (!$success) {
        echo "\n🔄 Пробуем через временный файл...\n";
        $temp_file = '/tmp/hosts_' . time();
        if (file_put_contents($temp_file, $content) !== false) {
            exec("cp '$temp_file' '$hosts_file' 2>&1", $output, $return_code);
            unlink($temp_file);

            if ($return_code === 0) {
                $success = true;
                echo "✅ Сохранено через копирование\n";
            } else {
                $error_message = "Ошибка копирования: " . implode("\n", $output);
            }
        } else {
            $error_message = "Не удалось создать временный файл";
        }
    }

    // Метод 3: Пробуем изменить права
    if (!$success) {
        echo "\n🔄 Пробуем изменить права...\n";
        exec("chmod 666 '$hosts_file' 2>&1", $output, $chmod_code);
        if ($chmod_code === 0) {
            $result = file_put_contents($hosts_file, $content);
            if ($result !== false) {
                $success = true;
                echo "✅ Сохранено после изменения прав\n";
            } else {
                $error_message = "Ошибка записи после chmod";
            }
        } else {
            $error_message = "Не удалось изменить права: " . implode("\n", $output);
        }
    }

    if ($success) {
        echo "\n🎉 ФАЙЛ УСПЕШНО СОХРАНЕН!\n";
        echo "Путь: $hosts_file\n";
        echo "Права: " . substr(sprintf('%o', fileperms($hosts_file)), -4) . "\n";
        echo "Размер: " . filesize($hosts_file) . " байт\n";
        echo "SUCCESS: File saved successfully";
    } else {
        http_response_code(500);
        echo "\n❌ ОШИБКА СОХРАНЕНИЯ\n";
        echo "Сообщение: $error_message\n";
        echo "Файл: $hosts_file\n";
        echo "Права: " . (file_exists($hosts_file) ? substr(sprintf('%o', fileperms($hosts_file)), -4) : 'нет файла') . "\n";
        echo "Доступен для записи: " . (is_writable($hosts_file) ? 'да' : 'нет') . "\n";
        echo "Владелец: " . (file_exists($hosts_file) ? (posix_getpwuid(fileowner($hosts_file))['name'] ?? 'unknown') : 'нет файла') . "\n";
        echo "ERROR: Save failed";
    }
} else {
    http_response_code(405);
    echo "ERROR: Method not allowed";
}
?>
