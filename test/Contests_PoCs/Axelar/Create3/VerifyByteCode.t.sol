// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Create3Address } from './Create3Address.sol';
import { CreateDeploy } from './CreateDeploy.sol';

import {Test, console} from "forge-std/Test.sol";


// TokenTransferTest is a contract that sets up and runs the test
contract VerifyByteCode is Test {

    bytes internal constant CREATE_DEPLOY_BYTECODE =
        hex'608060405234801561001057600080fd5b50610162806100206000396000f3fe60806040526004361061001d5760003560e01c806277436014610022575b600080fd5b61003561003036600461007b565b610037565b005b8051602082016000f061004957600080fd5b50565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b60006020828403121561008d57600080fd5b813567ffffffffffffffff808211156100a557600080fd5b818401915084601f8301126100b957600080fd5b8135818111156100cb576100cb61004c565b604051601f8201601f19908116603f011681019083821181831017156100f3576100f361004c565b8160405282815287602084870101111561010c57600080fd5b82602086016020830137600092810160200192909252509594505050505056fea264697066735822122094780ce55d28f1d568f4e0ab1b9dc230b96e952b73d2e06456fbff2289fa27f464736f6c63430008150033';
    bytes32 internal constant CREATE_DEPLOY_BYTECODE_HASH = keccak256(CREATE_DEPLOY_BYTECODE);

    Create3Address create3Contract;

    // setUp function runs before each test, setting up the environment
    function setUp() public {
         create3Contract = new Create3Address();
    }

    function test_VerifyByteCode() external {

      bytes memory creationCode = type(CreateDeploy).creationCode;
      assertEq(creationCode, CREATE_DEPLOY_BYTECODE);

      bytes32 createDeployBytecodeHash = create3Contract.createDeployBytecodeHash();
      assertEq(CREATE_DEPLOY_BYTECODE_HASH, createDeployBytecodeHash);
    }
  
}