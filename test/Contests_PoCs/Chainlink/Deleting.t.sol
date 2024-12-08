//@audit => Verifying that an enum inside a struct inside a mapping is re-set to its default value when the mapping is cleared using the delete keyword

pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

contract Configs {

  enum Role {
    // No oracle role has been set for the address `a`
    Unset,
    // Signing address for the s_oracles[a].index'th oracle. I.e., report signatures from this oracle should ecrecover
    // back to address `a`.
    Signer,
    // Transmission address for the s_oracles[a].index'th oracle. I.e., if `a` report is received by
    // OCR2Aggregator.transmit in which msg.sender is  a, it is attributed to the s_oracles[a].index'th oracle.
    Transmitter
  }

  struct Oracle {
    uint8 index; // ─╮ Index of oracle in s_signers/s_transmitters.
    Role role; // ───╯ Role of the address which mapped to this struct.
  }

  mapping(uint8 ocrPluginType => mapping(address signerOrTransmiter => Oracle oracle)) internal s_oracles;

  function getAssignedRole(uint8 _ocrPluginType, address _account) public returns (Role) {
    return s_oracles[_ocrPluginType][_account].role;
  }

  function setSignerRole(uint8 _ocrPluginType, address _account) public {
    s_oracles[_ocrPluginType][_account].role = Role.Signer;
  }

  function setTransmitterRole(uint8 _ocrPluginType, address _account) public {
    s_oracles[_ocrPluginType][_account].role = Role.Transmitter;
  }

  function clearAccountRoles(uint8 _ocrPluginType, address _account) public {
    delete s_oracles[_ocrPluginType][_account];
  }

}


contract Deleteting is Test {
  Configs configContract = new Configs();

  function test_clearingRoles() public {
    address alice = vm.addr(100);

    configContract.setSignerRole(1, alice);
    Configs.Role accountRoleBefore = configContract.getAssignedRole(1, alice);
    assert(accountRoleBefore == Configs.Role.Signer);

    configContract.clearAccountRoles(1, alice);
    Configs.Role accountRoleAfter = configContract.getAssignedRole(1, alice);
    assert(accountRoleAfter == Configs.Role.Unset);
  }
  
}
