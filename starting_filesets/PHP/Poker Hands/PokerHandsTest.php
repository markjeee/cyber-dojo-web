<?php

require_once 'PHPUnit/Framework.php';
require_once 'PokerHands.php';

class PokerHandsTest extends PHPUnit_Framework_TestCase
{
    public function testAnswer()
    {
        $this->assertEquals(6 * 9, answer());
    }
}

?>
