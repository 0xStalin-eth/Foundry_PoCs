// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LendingProtocol} from "../src/LendingProtocol.sol";

contract CounterScript is Script {
    LendingProtocol public lendingProtocol;

    function setUp() public {}

    //@audit-info => Deploy the contract to anvil
      //forge script script/LendingProtocol.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account <hashedPrivateKey> --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    //@audit-info => See all the hashed private keys
      //cast wallet list
    function run() public {
        vm.startBroadcast();

        lendingProtocol = new LendingProtocol();

        vm.stopBroadcast();
    }
}