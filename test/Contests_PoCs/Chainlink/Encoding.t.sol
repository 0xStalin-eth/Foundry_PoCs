pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

contract Encoding is Test {
  function encodeAddress() public pure returns (bytes memory) {
    return abi.encode(address(10));
  }

  function test_encodingLength() public {
    bytes memory encodedAddress = encodeAddress();
    uint256 encodeAddressLength = encodedAddress.length;

    console2.log("encodeAddressLength: ", encodeAddressLength);
    assertEq(encodeAddressLength, 32);
  }
}