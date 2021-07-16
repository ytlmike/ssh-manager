<?php

namespace Lib;

use Illuminate\Console\Concerns\InteractsWithIO;
use Illuminate\Console\OutputStyle;
use Symfony\Component\Console\Input\ArgvInput;
use Symfony\Component\Console\Output\ConsoleOutput;

class Manager
{
    use InteractsWithIO;

    /**
     * @var array $argv
     */
    protected $argv;

    /**
     * @var string[] $env
     */
    protected $env;

    /**
     * @var string $user
     */
    protected $user;

    /**
     * @var string $connectName
     */
    protected $connectName;

    protected $tags = [];

    public function __construct()
    {
        $input = new ArgvInput();
        $output = new ConsoleOutput();
        $this->setOutput(new OutputStyle($input, $output));
        $this->setInput($input);

        $this->init();
        $this->readParams();
    }

    public function run()
    {
        $table = new Table(ROOT_PATH . '/list.csv', $this->connectName, $this->tags);
        $id = 1;
        if (count($table->configs) < 2) {
            $this->warn("没有匹配的配置");
            return;
        }

        $table->print();

        if (count($table->configs) > 2) {
            $id = $this->ask("请输入要连接的服务器序号");
            while (!isset($table->configs[$id])) {
                $this->warn(" 输入无效，请重新输入");
                $id = $this->ask("请输入要连接的服务器序号");
            }
        }

        $this->info("正在连接...");

        $config = $table->configs[$id]->data;

        $client = new Client($config[Table::ROW_HOST], $config[Table::ROW_PORT], $this->user);
        $client->connect();
    }

    protected function help()
    {
        echo "usage: $this->argv[0] [-n name] [-t tag1,tag2] \n";
        exit(0);
    }

    protected function init()
    {
        $envPath = ROOT_PATH . '/.env';
        $listPath = ROOT_PATH . '/list.csv';
        if (!file_exists($envPath)) {
            $this->error("未检测到.env文件");
            exit(1);
        }
        if (!file_exists($listPath)) {
            $this->error("未检测到列表文件list.csv");
            exit(1);
        }
        $this->env = parse_ini_file(ROOT_PATH . '/.env');
        $this->user = $this->env['USERNAME'] ?? '';
        if (empty($this->user)) {
            $this->error(".env文件缺少USERNAME项");
            exit(1);
        }
        $this->argv = $_SERVER['argv'];
    }

    protected function readParams()
    {
        $flag = $this->argv[1] ?? "";
        if (empty($flag)) {
            return;
        }
        if ($flag[0] != '-') {
            $this->connectName = $flag;
            return;
        }
        if (!isset($this->argv[2])) {
            $this->help();
        }

        switch ($flag) {
            case "-n":
                if (empty($this->argv[2])) {
                    $this->help();
                } else {
                    $this->connectName = $this->argv[2];
                }
                break;
            case "-t":
                if (empty($this->argv[2])) {
                    $this->help();
                } else {
                    $this->tags = explode(',', $this->argv[2]);
                }
                break;
            default:
                $this->help();
        }
    }
}