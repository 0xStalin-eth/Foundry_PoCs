pragma solidity ^0.8.13;

import {EnumerableSetUpgradeable} from "./EnumerableSetUpgradeable.sol";

import {Test, console2} from "forge-std/Test.sol";

contract SimpleDelegations {

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
      console2.log("delegatees.lenght: ", unclaimed[msg.sender].delegatees.length());
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

  //@audit-recommendation => This would be the fix for the first bug!
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

    //@audit-issue => Removes an undelegated delegatee from the delegator's delegatees!
    if (unclaimed[delegator].undelegated[delegatee]) {
      //@audit-issue => The `unclaimed[delegator].delegatees.length()` shrinks, causing the for loop to not iterate over all the delegatees!
      unclaimed[delegator].delegatees.remove(delegatee);
      delete unclaimed[delegator].undelegated[delegatee];
    }
  }

  function getDelegatees() external view returns (address[] memory) {
    return unclaimed[msg.sender].delegatees.values();
  }
}

contract BugWhenClaimingAllRewards is Test {
  function test_claimingAllRewardsReproducingBug() public {
    SimpleDelegations delegations = new SimpleDelegations();

    delegations.addDelegatee(address(1));
    delegations.addDelegatee(address(2));
    delegations.addDelegatee(address(3));
    // delegations.addDelegatee(address(4));
    // delegations.addDelegatee(address(5));

    delegations.undelegate(address(1));
    delegations.undelegate(address(3));
    // delegations.undelegate(address(4));

    //@audit => Should claim 30 of rewards! There are 3 delegatees and each delegatee gives 10 of rewards
    uint256 rewards = delegations.claimAll();
    console2.log("Total rewards: ", rewards);

    console2.log("delegatees list after claiming");
    address[] memory delegatees = delegations.getDelegatees();
    for(uint i = 0; i < delegatees.length; i++) {
      console2.log("delegatee: ", delegatees[i]);
    }

    //@audit => If all delegatees would have been claimed, then, delegatees 1,2 & 4 would have been deleted from the `unclaimed.delegatees` AddressSet, but because the delegatee 4 was never reached (and the rewards of this delegatee were not claimed), this delegatee is still part of the list of delegatees for the delegator!
  }
}