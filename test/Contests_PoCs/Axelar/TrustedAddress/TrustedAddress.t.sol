// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {Test} from "forge-std/Test.sol";

contract TrustedAddressTest is Test {

    string internal constant ITS_HUB_ROUTING_IDENTIFIER = 'hub';
    bytes32 internal constant ITS_HUB_ROUTING_IDENTIFIER_HASH = keccak256(abi.encodePacked(ITS_HUB_ROUTING_IDENTIFIER));

    function test_TrustedAddress() external {
      string memory address_ = string('hub');
      bytes32 addressHash = keccak256(bytes(address_));

      assertEq(addressHash,ITS_HUB_ROUTING_IDENTIFIER_HASH);
    }
}
