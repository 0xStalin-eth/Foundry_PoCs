// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract LowLevelCalls {

    function entryPoint(address target, uint256 _value) public {
        // target.call{value: _value}("");
        internalCall(target, _value);
    }

    function internalCall(address target, uint256 _value) internal {
        // target.call{value: _value}("");
        bool success = false;
        assembly {
            success := call(
            gas(),
            target,
            _value,
            0,
            0,
            0,
            0
            )
        }
    }    

}

contract TestingLowLevelCalls is Test {

    LowLevelCalls lowLevelCallsContract = LowLevelCalls(new LowLevelCalls());
    

    function test_low_level_call() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user2, 10 ether);

        assertEq(user1.balance, 0);

        vm.prank(user2);
        //@audit-info => Requires the `payable` modifier because is sending eth
        // lowLevelCallsContract.entryPoint{value: 1 ether}(user1, 1 ether);
        
        //@audit-info => doesn't require `payable` modifier because is not sending eth
        //@audit-info => though, this requires the contract to have native on its balance!
        lowLevelCallsContract.entryPoint(user1, 1 ether);

        assertEq(user1.balance, 1 ether);
    }
}