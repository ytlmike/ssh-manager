<?php

use Illuminate\Console\Concerns\HasParameters;
use Illuminate\Console\Concerns\InteractsWithIO;
use Symfony\Component\Console\Input\ArgvInput;
use Symfony\Component\Console\Output\ConsoleOutput;
use Illuminate\Console\OutputStyle;

class Command
{
    use HasParameters, InteractsWithIO;

    public function __construct() {
        $input = new ArgvInput();
        $output = new ConsoleOutput();
        $this->setOutput(new OutputStyle($input, $output));
        $this->setInput($input);
    }
}