// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AddressBytes} from "./AddressBytes.sol";

import {Test} from "forge-std/Test.sol";

contract DecodeParams {
    using AddressBytes for bytes;

    function getTokenAddressFromParams(bytes calldata params_) external pure returns (address tokenAddress_) {
        (, tokenAddress_) = abi.decode(params_, (bytes, address));
    }

    function setup_(bytes calldata params_) external returns (address operator) {
        bytes memory operatorBytes = abi.decode(params_, (bytes));

        operator = address(0);

        if (operatorBytes.length != 0) {
            operator = operatorBytes.toAddress();
        }
    }
}

contract DecodeParamsTest is Test {
    DecodeParams decodeContract;

    using AddressBytes for address;

    // setUp function runs before each test, setting up the environment
    function setUp() public {
        decodeContract = new DecodeParams();
    }

    function test_DecodeParams() external {
      address minter = address(5);
      bytes memory minterBytes = minter.toBytes();

      address tokenAddress = address(10);
      
      address operator = decodeContract.setup_(abi.encode(minterBytes,tokenAddress));
      assertEq(operator, minter);

      address tokenAddress_ = decodeContract.getTokenAddressFromParams(abi.encode(minterBytes,tokenAddress));
      assertEq(tokenAddress, tokenAddress_);
    }
}
