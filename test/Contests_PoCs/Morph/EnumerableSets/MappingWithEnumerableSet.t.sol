pragma solidity ^0.8.13;

import {EnumerableSetUpgradeable} from "./EnumerableSetUpgradeable.sol";

import {Test, console2} from "forge-std/Test.sol";

contract Votes {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  mapping(uint256 proposalID => EnumerableSetUpgradeable.AddressSet) internal votes;

  function vote(uint256 proposalID) external {
    votes[proposalID].add(msg.sender);
  }

  function isVoted(uint256 proposalID, address voter) external view returns (bool) {
    return votes[proposalID].contains(voter);
  }

  function executeProposal(uint256 proposalID) external {
    //@audit => It is a known limitation that EnumerableSets can't be cleaned up
    //@audit => Using mappins to handle multiple EunmerableSets seems to be the best way to `clear` old EnumerableSets!
    //@audit => https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3256
    delete votes[proposalID];
  }

}


contract MappingWithEnumerableSet is Test {

  address user1 = vm.addr(1);
  address user2 = vm.addr(2);
  address user3 = vm.addr(3);
    
  function test_deleteMappingWithEnumerableSet() public {
    Votes votes = new Votes();

    vm.startPrank(user1);
    votes.vote(1);
    votes.vote(2);
    votes.vote(3);
    vm.stopPrank();

    vm.startPrank(user2);
    votes.vote(1);
    votes.vote(2);
    votes.vote(3);
    vm.stopPrank();

    vm.startPrank(user3);
    votes.vote(1);
    votes.vote(2);
    votes.vote(3);
    vm.stopPrank();

    bool user1VotedProposal1 = votes.isVoted(1, user1);
    bool user1VotedProposal2 = votes.isVoted(2, user1);
    bool user1VotedProposal3 = votes.isVoted(3, user1);
    assert(user1VotedProposal1 == true);
    assert(user1VotedProposal2 == true);
    assert(user1VotedProposal3 == true);

    votes.executeProposal(1);
    votes.executeProposal(2);
    votes.executeProposal(3);


    bool user1VotedProposal1After = votes.isVoted(1, user1);
    bool user1VotedProposal2After = votes.isVoted(2, user1);
    bool user1VotedProposal3After = votes.isVoted(3, user1);
    assert(user1VotedProposal1After == true);
    assert(user1VotedProposal2After == true);
    assert(user1VotedProposal3After == true);

  }

}