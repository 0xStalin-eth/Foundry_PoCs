pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";


contract PopFromArray {

  struct Undelegation {
    address delegatee;
    uint256 amount;
  }

  mapping(address delegator => Undelegation[]) public undelegations;

  bool rewardStarted;

  event UndelegationClaimed(
      address indexed delegatee,
      address indexed delegator
      // address indexed delegator,
      // uint256 unlockEpoch,
      // uint256 amount
  );

  constructor() {
    rewardStarted = false;
  }

  function undelegateStake(address delegatee) external {
    uint256 delegations = 10e18;
    
    Undelegation memory undelegation = Undelegation(delegatee, delegations);

    undelegations[_msgSender()].push(undelegation); 
  }

  function claimUndelegation() external {
    uint256 totalAmount;
    uint256 length = undelegations[_msgSender()].length;

    for (uint256 i = 0; i < length; ) {
        // // if the reward is not started yet, claiming directly is allowed
        // if (!rewardStarted || undelegations[_msgSender()][i].unlockEpoch <= currentEpoch()) {
        if (!rewardStarted) {
            totalAmount += undelegations[_msgSender()][i].amount;

            // // event params
            address delegatee = undelegations[_msgSender()][i].delegatee;
            // uint256 unlockEpoch = undelegations[_msgSender()][i].unlockEpoch;
            uint256 amount = undelegations[_msgSender()][i].amount;

            if (i < length - 1) {
                undelegations[_msgSender()][i] = undelegations[_msgSender()][length - 1];
            }
            undelegations[_msgSender()].pop();
            length = length - 1;

            emit UndelegationClaimed(delegatee, _msgSender());
            // emit UndelegationClaimed(delegatee, _msgSender(), unlockEpoch, amount);

            console2.log("popped from array");
        } else {
            i = i + 1;

            console2.log("increased i");
        }
    }
    require(totalAmount > 0, "no Morph token to claim");
  }


  function _msgSender() internal view virtual returns (address) {
      return msg.sender;
  }
}

contract TestClaimDelegations is Test {
  function test_ClaimUndelegations() public {
    PopFromArray undelegationContract = new PopFromArray();

    address user1 = vm.addr(1);
    vm.startPrank(user1);

    undelegationContract.undelegateStake(address(100));
    undelegationContract.undelegateStake(address(200));
    undelegationContract.undelegateStake(address(300));
    undelegationContract.undelegateStake(address(400));

    undelegationContract.claimUndelegation();

    vm.stopPrank();

  }

}