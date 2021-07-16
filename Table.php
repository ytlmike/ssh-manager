<?php

include_once 'Row.php';

class Table
{
    const CELL_BLANK = 2;

    const ROW_SERIAL = 'ID';
    const ROW_TAGS = 'Tags';
    const ROW_NAME = 'Name';
    const ROW_HOST = 'Host';
    const ROW_PORT = 'Port';
    const ROW_USER = 'User';

    const TAGS_SEPARATOR = '|';

    /** @var Row[] */
    public $configs = [];

    public $printOrder = [
        Table::ROW_SERIAL,
        Table::ROW_TAGS,
        Table::ROW_HOST,
        Table::ROW_PORT,
        Table::ROW_NAME,
    ];

    // 各部分在配置文件中的列号
    public $rowCsvPart = [
        Table::ROW_SERIAL => 0,
        Table::ROW_TAGS => 1,
        Table::ROW_HOST => 2,
        Table::ROW_PORT => 3,
        Table::ROW_USER => 4,
        Table::ROW_NAME => 5,
    ];

    // 各列默认值
    public $rowDefaultValues = [
        Table::ROW_SERIAL => NULL,
        Table::ROW_TAGS => NULL,
        Table::ROW_HOST => NULL,
        Table::ROW_PORT => '22',
        Table::ROW_NAME => '',
        Table::ROW_USER => '',
    ];

    public $rowLens = [
        Table::ROW_SERIAL => 0,
        Table::ROW_TAGS => 0,
        Table::ROW_HOST => 0,
        Table::ROW_PORT => 0,
        Table::ROW_NAME => 0,
        Table::ROW_USER => 0,
    ];

    /**
     * @throws Exception
     */
    public function __construct($listFile, $name , $tags)
    {
        $handle = fopen($listFile, 'r+');
        if (!$handle) {
            throw new Exception("打开配置文件失败");
        }
        $this->configs[0] = new Row($this, $this->printOrder);
        $serial = 1;
        while ($line = fgetcsv($handle)) {
            array_unshift($line, $serial);
            $tagArr = explode(Table::TAGS_SEPARATOR, $line[$this->rowCsvPart[self::ROW_TAGS]]);
            if (!empty($name)) {
                $nameKey = $this->rowCsvPart[self::ROW_NAME];
                $thisName = isset($line[$nameKey]) ? trim($line[$nameKey]) : "";
                if ($thisName != $name) {
                    continue;
                }
            } elseif (!empty($tags)) {
                if (count(array_diff($tags, $tagArr)) > 0) {
                    continue;
                }
            }
            $this->configs[$serial] = new Row($this, $line);
            $serial++;
        }
    }

    public function print()
    {
        $this->printBorder();
        foreach ($this->configs as $config) {
            $config->print();
        }
    }

    public function rowWidth(string $rowKey) : int
    {
        return $this->rowLens[$rowKey] + 2 * Table::CELL_BLANK;
    }

    public function printBorder()
    {
        echo "+";
        foreach ($this->printOrder as $rowKey) {
            $rowLen = $this->rowLens[$rowKey];
            for ($i = 0; $i < $rowLen + 4; $i++) {
                echo "-";
            }
            echo "+";
        }
        echo "\n";
    }

    public function printCell(string $rowKey, string $str)
    {
        $strWidth = myStrLen($str);
        $rowWidth = $this->rowWidth($rowKey);
        $blankCount = $rowWidth - $strWidth;
        $front = intval($blankCount / 2);
        $behind = $blankCount - $front;

        for ($i = 0; $i < $front; $i++) {
            echo " ";
        }
        echo $str;
        for ($i = 0; $i < $behind; $i++) {
            echo " ";
        }
        echo "|";
    }

    public function handleRowLen($key, $len)
    {
        $this->rowLens[$key] = max($this->rowLens[$key], $len);
    }
}