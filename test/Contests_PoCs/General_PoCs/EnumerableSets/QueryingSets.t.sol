pragma solidity ^0.8.13;

import {EnumerableSetUpgradeable} from "./EnumerableSetUpgradeable.sol";

import {Test, console2} from "forge-std/Test.sol";


//@audit => Verify that querying a position bigger than the length of the set doesn't cause the tx to revert!

contract QueryingSets {

  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  struct Unclaimed {
      EnumerableSetUpgradeable.AddressSet delegatees;
      mapping(address delegator => bool undelegated) undelegated;
      // mapping(address delegator => uint256 startEpoch) unclaimedStart;
      // mapping(address delegator => uint256 endEpoch) unclaimedEnd;
  }

  mapping(address delegator => Unclaimed) private unclaimed;

  function addDelegatee(address delegatee) external {
    unclaimed[msg.sender].delegatees.add(delegatee);
  }
  
  function undelegate(address delegatee) external {
    unclaimed[msg.sender].undelegated[delegatee] = true;
  }

  //@audit-issue => Existing logic that causes to not claim all the delegatees
  //@audit-issue => The problem is that when there are undelegated delegatees, they will be removed from the delegator in the `_claim()`, which makes the `unclaimed.delegatees` AddressSet lenght to shrink, which unintentionally causes the for loop to do less iterations than the original amount of delegatees at the begining of the call!
  function claimAll() external returns (uint256 reward) {
    for (uint256 i = 0; i < unclaimed[msg.sender].delegatees.length(); i++) {
      address delegatee = unclaimed[msg.sender].delegatees.at(i);
      // console2.log("i: ", i);
      console2.log("delegatee: ", delegatee);
      if (
          unclaimed[msg.sender].delegatees.contains(delegatee)
          // unclaimed[delegator].unclaimedStart[delegatee] <= endEpochIndex
      ) {
          reward += _claim(delegatee, msg.sender);
      }

    }
  }

  //@audit-recommendation
  // function claimAll() external returns (uint256 reward) {
  //   uint256 totalDelegatees = unclaimed[msg.sender].delegatees.length();
  //   address[] memory delegatees = new address[](totalDelegatees);

  //   //@audit => Make a temporal copy of the current delegates of the delegator
  //   for (uint256 i = 0; i < unclaimed[msg.sender].delegatees.length(); i++) {
  //       delegatees[i] = unclaimed[msg.sender].delegatees.at(i);
  //   }

  //   //@audit => Iterate over the temporal copy, in this way, if a delegatee is removed from the AddressSet, the for loop will still iterate over all the delegatees at the start of the call!
  //   for (uint256 i = 0; i < delegatees.length; i++) {
  //     // console2.log("delegatee: ", delegatees[i]);
  //     if (
  //         unclaimed[msg.sender].delegatees.contains(delegatees[i])
  //         // unclaimed[delegator].unclaimedStart[delegatees[i]] <= endEpochIndex
  //     ) {
  //         reward += _claim(delegatees[i], msg.sender);
  //     }
  //   }
  // }

  function _claim(address delegatee, address delegator) internal returns(uint256 reward) {
    require(unclaimed[delegator].delegatees.contains(delegatee), "no remaining reward");
    
    reward = 10;

    if (unclaimed[delegator].undelegated[delegatee]) {
      unclaimed[delegator].delegatees.remove(delegatee);
      delete unclaimed[delegator].undelegated[delegatee];
    }
  }

  function getDelegatees() external view returns (address[] memory) {
    return unclaimed[msg.sender].delegatees.values();
  }
}

contract QueryingSetsTests is Test {
  function test_QueryingSetInPositionGreatherThanSetLength() public {
    QueryingSets queryingContract = new QueryingSets();

    queryingContract.addDelegatee(address(1));
    queryingContract.addDelegatee(address(2));
    queryingContract.addDelegatee(address(3));
    // queryingContract.addDelegatee(address(4));
    // queryingContract.addDelegatee(address(5));

    queryingContract.undelegate(address(1));
    queryingContract.undelegate(address(3));
    // queryingContract.undelegate(address(4));

    uint256 rewards = queryingContract.claimAll();
    console2.log("Total rewards: ", rewards);

    console2.log("delegatees list after claiming");
    address[] memory delegatees = queryingContract.getDelegatees();
    for(uint i = 0; i < delegatees.length; i++) {
      console2.log("delegatee: ", delegatees[i]);
    }

    //@audit => If all delegatees would have been claimed, then, delegatees 1,2 & 4 would have been deleted from the `unclaimed.delegatees` AddressSet, but because the delegatee 4 was never reached (and the rewards of this delegatee were not claimed), this delegatee is still part of the list of delegatees for the delegator!
  }
}