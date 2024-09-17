// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {L1Staking} from "./L1Staking.sol";
import {Messenger} from "./Messenger.sol";



contract MessageValueInCalls is Test {
  address user1 = vm.addr(1);

  address feeVault = address(10);
  Messenger messenger;
  L1Staking public staking;
  uint256 public STAKING_VALUE = 1 ether;

  // function setup() public {
  //   // feeVault = vm.addr(10);
  //   // messenger = new Messenger(feeVault);
  //   // staking = new L1Staking();
  // }

  //@audit => The result is that the msg.value in each internal call is not automatically forwarded, it is required that the caller function explicitly sends some native token, otherwise, msg.value will be 0!

  function test_MessageValueBetweenCalls() public {
    feeVault = vm.addr(10);
    messenger = new Messenger(feeVault);
    staking = new L1Staking(address(messenger));
    
    vm.deal(user1, 5 ether);

    assertEq(feeVault.balance,0);
    assertEq(user1.balance,5 ether);

    // console2.log("staking contract address:" , address(staking));

    vm.prank(user1);
    staking.registerStaker{value: STAKING_VALUE}();
    // assertEq(staking.testFunction(),true);

    assertEq(feeVault.balance, 0.1 ether);
  }


}
