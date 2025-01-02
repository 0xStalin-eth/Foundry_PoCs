pragma solidity ^0.8.13;

contract LendingProtocol {
  // mapping (address => uint256) public balanceOf;
  mapping (address => uint256) private balanceOf;

  function deposit() payable external {
    balanceOf[msg.sender] += msg.value;
  }

  function accountBalance(address _account) external view returns (uint256) {
    return balanceOf[_account];
  }
}