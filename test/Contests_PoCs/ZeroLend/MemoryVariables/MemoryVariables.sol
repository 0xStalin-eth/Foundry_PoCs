// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {Test, console2} from "forge-std/Test.sol";

contract MemoryVariables is Test {

    struct DataType {
      uint256 value;
    }

    function function1() public view returns (DataType memory) {
      DataType memory cache;
      cache.value = 100;

      //@audit => Any update to the value of the variable in the function2() will be preserved in memory after execution comes back to this function
      function2(cache);
      //@audit => Any update made on the function2() is now reflected on the cache variable.

      if(cache.value == 100) revert("internal function did not change the value of a memory variable");

      //@audit => The value of the cache memory variable is the value set in the function2!
      return cache;
    }

    function function2(DataType memory cache) internal pure {
      //@audit => The value of the variable will be updated to 1. Even though is a memory variable, the value is preserved when the execution returns back to the caller function
      cache.value = 1;
    }

    function test_MemoryVariableValue() external {
      DataType memory cache = function1();
      console2.log("Value of cache variable after: ", cache.value);
      assert(cache.value == 1);

      //@audit => Changes to the value of a memory variable between functions is preserved.
      //@audit => The difference between storage and memory is that after the execution is completed, the values of the memory variable are totally wiped out.
      //@audit => Values of a memory variable are preserved in between functions during the same tx!
    }
}
