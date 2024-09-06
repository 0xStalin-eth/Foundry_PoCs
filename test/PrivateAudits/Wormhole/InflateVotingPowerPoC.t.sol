// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {ERC20VotesFake} from "./helpers/ERC20VotesFake.sol";

/*
- The purpose of this PoC is to demonstrate how to set up a 100k token transfers before running a test!
*/

contract SpokeVoteAggregatorTest is Test {
  ERC20VotesFake public token;


  address maliciousUser = vm.addr(1);
  address maliciousUser2 = vm.addr(2);
  address legitUser = vm.addr(10);
  uint _amount = 100e18;
  uint256 _proposalId = 10;
  uint48 voteStartPoC;

  function beforeTestSetup(
        bytes4 testSelector
    ) public returns (bytes[] memory beforeTestCalldata) {
        if (testSelector == CastVote.testDoSUsersFromVoting_PoC.selector) {
            beforeTestCalldata = new bytes[](25);
            // beforeTestCalldata[0] = abi.encodePacked(this.deployToken.selector);
            beforeTestCalldata[0] = abi.encodeWithSignature("_mintAndDelegate(address,uint256)", legitUser, _amount);
            beforeTestCalldata[1] = abi.encodeWithSignature("_mintAndDelegate(address,uint256)", maliciousUser, _amount);
            beforeTestCalldata[2] = abi.encodeWithSignature("_mintAndDelegate(address,uint256)", maliciousUser2, 1e18);

            beforeTestCalldata[3] = abi.encodePacked(this.createProposal.selector);

            beforeTestCalldata[4] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[5] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[6] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[7] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[8] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[9] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[10] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[11] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[12] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[13] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[14] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[15] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[16] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[17] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[18] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[19] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[20] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[21] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[22] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[23] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);
            beforeTestCalldata[24] = abi.encodeWithSignature("testTransfer(address,address)", maliciousUser2, legitUser);

        }
    }

  function setUp() public {
    token = new ERC20VotesFake();
  }


  function testTransfer(address sender, address receiver) public {
    vm.startPrank(sender);
    uint256 timestamp;
    for(uint i = 0; i < 5_000; i++) {
      token.transfer(receiver, 1);
      timestamp = vm.getBlockTimestamp();
      vm.warp(timestamp + 1);
    }
    vm.stopPrank();
  }


  function _mintAndDelegate(address user, uint256 _amount) public returns (address) {
    token.mint(user, _amount);
    vm.prank(user);
    token.delegate(user);
    return user;
  }

}


contract CastVote {

  function testDoHugeAmountOfTransfersBeforeRunningTest() public
  {
    vm.warp(voteStartPoC);

    console2.log("This PoC shows how to do 100k transfers before actually running a test");

    // vm.prank(maliciousUser);
    // spokeVoteAggregator.castVote(_proposalId, uint8(SpokeCountingFractional.VoteType.For));

    // vm.prank(legitUser);
    // spokeVoteAggregator.castVote(_proposalId, uint8(SpokeCountingFractional.VoteType.Against));

    // console2.log("voteStart" , voteStartPoC);
  }

}
