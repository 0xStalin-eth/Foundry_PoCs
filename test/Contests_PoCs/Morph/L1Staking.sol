interface ICrossDomainMessenger {
  function sendMessage(uint256 value) external payable;
}

contract L1Staking {
  uint256 stakingValue = 1 ether;
  ICrossDomainMessenger public immutable MESSENGER;

  constructor(address messenger) {
    MESSENGER = ICrossDomainMessenger(messenger);
  }

  function registerStaker() external payable {
    require(msg.value == stakingValue);
    MESSENGER.sendMessage(0);
  }

}
