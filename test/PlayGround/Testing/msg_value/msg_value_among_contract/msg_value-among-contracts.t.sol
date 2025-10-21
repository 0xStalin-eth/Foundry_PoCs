// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
// import "forge-std/console.sol";


contract ContractB {
    ContractC contractC;

    function setContractC(address _contractC) external {
        contractC = ContractC(_contractC);
    }

    function deposit() external payable {
        // step2: ContractB calls Contract without forwarding native
            // It does not forward native, it only passes the numerical value received in msg.value, but this is not forwarding native per se!
        contractC.middleMan(msg.value);
    }

    function callback(uint256 value) external {
        // step4: ContractB receives callback from ContractC, no msg.value received on this call, ContractB still has the native received from ContractA on step1
        assert(address(this).balance == value);
    }
}

contract ContractC {
    ContractB contractB;

    constructor(address _contractB) {
        contractB = ContractB(_contractB);
    }

    function middleMan(uint256 value) external {
        // step3: ContractC callbacks ContractB to validate ContractB has access to the msg.value ContractA sent on step1
        contractB.callback(value);
    } 
}

contract ContractA is Test {

    ContractB contractB = new ContractB();
    ContractC contractC = new ContractC(address(contractB));    

    function test_msg_value_among_contracts() public {
        contractB.setContractC(address(contractC));
        
        // step1: ContractA calls ContractB passing some native via msg.value!
        contractB.deposit{value: 1 ether}();
    }
}