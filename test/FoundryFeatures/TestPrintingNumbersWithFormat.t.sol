pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";


contract TestPrintingNumbersWithFormat is Test {
    uint NUMBER = 0.9e17;
    function test_consoleLogE() public {
      console.log("Simple formating with e:  %e", NUMBER);      //9e16
      console.log("Formatted w/ 18 decimals: %18e", NUMBER);    //0.09
      console.log("No formating:            ", NUMBER);         //90000000000000000
    }
}