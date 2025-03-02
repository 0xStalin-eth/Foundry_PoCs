pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract ImplicitDowncasting is Test {
    
    // source => https://x.com/0xSilvermist/status/1875961228926836778
    function test_implicitDowncasting() public {
      uint256 originalValue = type(uint160).max;
      uint downcastedValue = uint160(originalValue + 2);

      assertEq(downcastedValue, 1);
      assertLt(downcastedValue, originalValue);
    }
}