// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

/*
- This PoC demonstrates the intrincasities of using a delegatecall to extend the execution of a contract on a final target
  - The Implementation Contract is the contract that gets delegatecalled to extend some custom logic before calling a final target contract

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

  //@audit => By using performDelegateCall(), the operation been executed can extend some custom logic before the actuall call to the Target contract.
    //@audit => The Target contract requirement that only the airlock can call it is passed, and the storage of the Target contract is also updated!
  function performDelegateCall(address _target, bytes memory _calldata) external payable returns (bytes memory) {
    if (msg.sender != address(this)) revert InvalidCaller();
    (bool _success, bytes memory _returndata) = _target.delegatecall(_calldata);
    require(_success, "delegatecall from SpokeAirlock to target failed");
  }
}

contract ImplementationContract {
  function extendComplexLogic(address _target) external {
    uint256 oraclePrice = 100e18;
    bytes memory _calldata = abi.encodeWithSignature("callFunction(uint256)", oraclePrice);
    (bool _success, bytes memory _returndata) = _target.call(_calldata);
    require(_success, "call from Implementation to target failed");
  }
}

contract TargetContract {
  address airlock;
  uint256 public price;
  constructor(address _airlock) {
    airlock = _airlock;
  }

  function callFunction(uint256 _price) external {
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
    implementation = new ImplementationContract();
  }

  //@audit => Using an Implementation contract to extend some custom logic for the call to the Target contract!
  function test_performDelegateCall() external {
    bytes memory _calldataToToImplementation = abi.encodeWithSignature("extendComplexLogic(address)", address(target));
    bytes memory payload = abi.encodeWithSignature("performDelegateCall(address,bytes)",address(implementation),_calldataToToImplementation);
    executor.receiveMessage(address(airlock), 0, payload);

    require(target.price() != 0);
  }

}