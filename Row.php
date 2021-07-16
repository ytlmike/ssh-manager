<?php

include_once 'Table.php';

class Row
{
    public $data;
    protected $main;

    /**
     * @throws Exception
     */
    public function __construct(Table $main, array $data)
    {
        $this->main = $main;
        foreach ($this->main->rowCsvPart as $key => $index) {
            if (!isset($data[$index]) && $this->main->rowDefaultValues[$key] === NULL) {
                throw new Exception('配置错误：' . implode(',', $data));
            }
            $this->data[$key] = isset($data[$index]) ? trim($data[$index]) : $this->main->rowDefaultValues[$key];
            $this->main->handleRowLen($key, myStrLen($this->data[$key]));
        }
    }

    public function print()
    {
        echo "|";
        foreach ($this->main->printOrder as $rowKey) {
            $str = is_array($this->data[$rowKey]) ? implode(',', $this->data[$rowKey]) : $this->data[$rowKey];
            $this->main->printCell($rowKey, $str);
        }
        echo "\n";
        $this->main->printBorder();
    }
}