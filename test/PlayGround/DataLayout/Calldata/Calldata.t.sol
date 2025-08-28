// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract Calldata is Test {
    function test_SeeEncoding_Example1() external pure returns (bytes memory) {
        address buyer = address(10);
        uint256 amount = 100;
        return abi.encodeWithSignature("buyToken(address,uint256)", buyer, amount);
    }

    function test_SeeEncoding_Example2() external pure returns (bytes memory) {
        address buyer = address(10);
        uint32 amount = 100;
        return abi.encodeWithSignature("buyToken(address,uint32)", buyer, amount);
    }
}