// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

/*
- This PoC demonstrates how not using a delegatecall to extend custom logic before calling a final target contract would not make possible to extend logic to call a permissioned contract
*/


contract Executor {
  SpokeAirlock public airlock;
  constructor() {
    airlock = new SpokeAirlock(address(this));
  }

  function receiveMessage(address _target, uint256 _value, bytes memory _calldata) external {
    airlock.executeOperations(_target, _value, _calldata);
  }
}

contract SpokeAirlock {
  address executor;

  error InvalidCaller();

  constructor(address _executor) {
    executor = _executor;
  }

  function executeOperations(address _target, uint256 _value, bytes memory _calldata)
    external
    payable
  {
    require(msg.sender == executor);

    (bool _success, bytes memory _returndata) = _target.call{value: _value}(_calldata);
    require(_success, "call to target failed");
  }

  // function performDelegateCall(address _target, bytes memory _calldata) external payable returns (bytes memory) {
  //   if (msg.sender != address(this)) revert InvalidCaller();
  //   (bool _success, bytes memory _returndata) = _target.delegatecall(_calldata);
  //   require(_success, "delegatecall from SpokeAirlock to target failed");
  // }
}

contract ImplementationContract {
  address airlock;
  uint256 public price;

  constructor(address _airlock) {
    airlock = _airlock;
  }

  function extendComplexLogic(address _target) external {
    uint256 oraclePrice = 100e18;
    bytes memory _calldata = abi.encodeWithSignature("callFunction(uint256)", oraclePrice);
    
    //@audit => Run the test `test_executeOperations` one time with the delegatecall uncommented (as it is)
    //@audit => For the second run, comment lines 59 & 60, and uncomment lines 63 & 64
    
    //@audit => If `ImplementationContract` delegatecalls into this function, the require() will pass, but any state changes will be made on the context of the ImplementationContract, the storage of the Target contract won't be updated
    (bool _success, bytes memory _returndata) = _target.delegatecall(_calldata);
    require(_success, "delegatecall from Implementation to target failed");
    
    //@audit => To update the storage of the Target contract, the Implementation contract would need to do a `call` instead of a `delegatecall`, and doing a call would case the require() to revert!
    // (bool _success, bytes memory _returndata) = _target.call(_calldata);
    // require(_success, "call from Implementation to target failed");
    
  }
}

contract TargetContract {
  address airlock;
  uint256 public price;
  constructor(address _airlock) {
    airlock = _airlock;
  }

  function callFunction(uint256 _price) external {
    console2.log("msg.sender: ", msg.sender);
    console2.log("airlock: ", airlock);
    require(msg.sender == airlock, "Caller is not Airlock");
    price = _price;
  }
}

contract SpokeAirlockTest is Test {
  Executor executor;
  SpokeAirlock airlock;
  TargetContract target;
  ImplementationContract implementation;

  function setUp() public {
    executor = new Executor();
    airlock = SpokeAirlock(executor.airlock());
    target = new TargetContract(address(airlock));
    implementation = new ImplementationContract(address(airlock));
  }

  //@audit => See comments on the Implementation contract!
  function test_executeOperations() external {
    bytes memory _calldataToToImplementation = abi.encodeWithSignature("extendComplexLogic(address)", address(target));
    executor.receiveMessage(address(implementation), 0, _calldataToToImplementation);
    require(target.price() != 0);
  }
}