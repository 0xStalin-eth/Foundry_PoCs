pragma solidity ^0.8.0;

import "forge-std/Test.sol";


contract EquisDe {
    uint256 internal counter;

    function publicFunction() public {
        counter++;
    }

    function getGounter() external view returns(uint256) {
        return counter;
    }

}

contract FunctionVisibility is Test {

    EquisDe contractTest = new EquisDe();
    
    function test_CallPublicFunction() public {
        contractTest.publicFunction();
        assertEq(contractTest.getGounter(), 1);
    }
}

abstract contract PausableUpgradeable {
    function beforeResume() public virtual {} // solhint-disable-line no-empty-blocks
}

contract Market is PausableUpgradeable {
    uint256 public lastUpdate;

    function beforeResume() internal override {
        lastUpdate++;    
    }
}