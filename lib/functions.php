<?php

function myStrLen(string $str)
{
    $chineseWordCount = (strlen($str) - mb_strlen($str)) / 2;
    return mb_strlen($str) + $chineseWordCount;
}