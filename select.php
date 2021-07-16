#!/usr/local/bin/php

<?php

include_once 'vendor/autoload.php';
include_once 'functions.php';
include_once 'Table.php';
include_once 'Row.php';
include_once 'Command.php';

$cmd = new Command();

readEnv();

$username = getenv('USERNAME');

$name = '';
$tags = [];
$flag = $argv[1] ?? "";

switch ($flag) {
    case "-n":
        if (empty($argv[2])) {
            help($argv);
        } else {
            $name = $argv[2];
        }
        break;
    case "-t":
        if (empty($argv[2])) {
            help($argv);
        } else {
            $tags = explode(',', $argv[2]);
        }
        break;
    default:
        if (!empty($flag)) {
            if ($flag[0] != '-') {
                $name = $flag;
            }else {
                help($argv);
            }
        }
}

$table = new Table(__DIR__ . '/list.csv', $name, $tags);

$id = 1;
if (count($table->configs) < 2) {
    $cmd->warn("没有匹配的配置");
    return;
}

$table->print();

if (count($table->configs) > 2) {
    $id = $cmd->ask("请输入要连接的服务器序号");
    while (!isset($table->configs[$id])) {
        $cmd->warn(" 输入无效，请重新输入");
        $id = $cmd->ask("请输入要连接的服务器序号");
    }
}

$cmd->info("正在连接...");

$config = $table->configs[$id]->data;
startSsh($username, $config[Table::ROW_HOST], $config[Table::ROW_PORT]);