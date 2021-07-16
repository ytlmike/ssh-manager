<?php

function myStrLen(string $str)
{
    $chineseWordCount = (strlen($str) - mb_strlen($str)) / 2;
    return mb_strlen($str) + $chineseWordCount;
}

function ask(string $str = ''): string
{
    fwrite(STDOUT, $str . ":");
    $result = trim(fgets(STDIN));
    return trim($result);
}

function help($argv)
{
    echo "usage: $argv[0] [-n name] [-t tag1,tag2] \n";
    exit(0);
}

function readEnv()
{
    $content = file_get_contents(__DIR__ . '/.env');
    $envs = explode("\n", $content);
    foreach ($envs as $env) {
        putenv($env);
    }
}

function startSsh($username, $host, $port = 22)
{
    $descriptors = array(
        array('file', '/dev/tty', 'r'),
        array('file', '/dev/tty', 'w'),
        array('file', '/dev/tty', 'w')
    );

    $process = proc_open("ssh -t -t -p $port $username@$host", $descriptors, $pipes);

    while (true) {
        $status = proc_get_status($process);
        if (! $status["running"]) break;
    }
    proc_close($process);
}
