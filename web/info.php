<?php
// Информация о системе и файле
header('Content-Type: application/json; charset=utf-8');

$hosts_file = '/etc/hosts';

$info = [
    'filename' => $hosts_file,
    'exists' => file_exists($hosts_file),
    'readable' => is_readable($hosts_file),
    'writable' => is_writable($hosts_file),
    'permissions' => file_exists($hosts_file) ? substr(sprintf('%o', fileperms($hosts_file)), -4) : '0000',
    'owner' => file_exists($hosts_file) ? posix_getpwuid(fileowner($hosts_file))['name'] : 'unknown',
    'php_user' => get_current_user(),
    'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'unknown'
];

echo json_encode($info, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
