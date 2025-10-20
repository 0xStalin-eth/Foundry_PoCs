// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
// import "forge-std/console.sol";

contract TargetContract {

    uint256 public totalDeposits;
    mapping(address receiver => uint256 deposits) public balances;

    function deposit(address receiver) external payable returns (uint256) {
        totalDeposits += msg.value;
        balances[receiver] += msg.value;
        return msg.value;
    } 

}

interface ITargetContract {
    function deposit(address receiver) external payable returns (uint256);
}

contract Testing2 is Test {

    address target = address(new TargetContract());
    

    function test_call_function_via_low_level_call() public {
        assertEq(TargetContract(target).totalDeposits(), 0);

        // Generate the calldata: selector + encoded receiver arg
        bytes memory callData = abi.encodeWithSelector(
            ITargetContract.deposit.selector,
            address(this)
        );

        // Perform the low-level call with value
        (bool success, bytes memory returnData) = target.call{value: 1 ether}(callData);

        // Check success
        assertTrue(success);

        // Decode and verify the returned uint256 (optional, but good for validation)
        uint256 returnedValue = abi.decode(returnData, (uint256));
        assertTrue(returnedValue == 1 ether);

        // Verify the deposit updated the state as expected
        assertEq(TargetContract(target).totalDeposits(), 1 ether);
        assertEq(TargetContract(target).balances(address(this)), 1 ether);
    }
}