<?php

namespace Lib;

class Client
{
    /**
     * @var string $host
     */
    protected $host;

    /**
     * @var int $port
     */
    protected $port;

    /**
     * @var string $user
     */
    protected $user;

    public function __construct($host, $port, $user)
    {
        $this->host = $host;
        $this->port = $port;
        $this->user = $user;
    }

    public function connect()
    {
        $descriptors = array(
            array('file', '/dev/tty', 'r'),
            array('file', '/dev/tty', 'w'),
            array('file', '/dev/tty', 'w')
        );
        $cmd = "ssh -t -t -p $this->port $this->user@$this->host";
        $process = proc_open($cmd, $descriptors, $pipes);

        while (true) {
            $status = proc_get_status($process);
            if (! $status["running"]) break;
        }
        proc_close($process);
    }
}