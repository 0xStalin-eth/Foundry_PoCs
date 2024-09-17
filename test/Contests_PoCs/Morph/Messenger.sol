
import {console2} from "forge-std/Test.sol";

contract Messenger {
  address feeVault;

  constructor(address _feeVault) {
    feeVault = _feeVault;
  }

  function sendMessage(uint256 value) external payable {
    _sendMessage(value);
  }

  function _sendMessage(uint256 _value) internal {
        // compute and deduct the messaging fee to fee vault.
        uint256 _fee = 0.1 ether;

        console2.log("msg.value in Messenger contract: ", msg.value);
       
        require(msg.value >= _fee + _value, "Insufficient msg.value");
        if (_fee > 0) {
            (bool _success, ) = feeVault.call{value: _fee}("");
            require(_success, "Failed to deduct the fee");
        }
    }
}