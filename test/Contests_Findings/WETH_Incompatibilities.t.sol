// https://github.com/code-423n4/2023-05-chainlink-findings/issues/593
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract WETH_Incompatibilities is Test {
    address alice = address(0x1);
    address bob = address(0x2);
    address whale = address(0x70d95587d40A2caf56bd97485aB3Eec10Bee6336);
    IERC20 public constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    function setUp() public {
      // transfer from a whale to alice
      vm.prank(whale);
      WETH.transfer(alice, 1e18);
    }

    // forge test --match-test test_WETHTransferFromIssue --fork-url {YOUR_RPC}.
    function test_WETHTransferFromIssue() public {
      vm.startPrank(alice);

      // IERC20(address(WETH)).transfer(bob, 1 ether); //@audit toggle this line on and the one below off to see the allowance problem
      IERC20(address(WETH)).transferFrom(alice, bob, 1 ether);
      vm.stopPrank();
    }
}