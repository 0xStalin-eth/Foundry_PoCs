pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {VictimVault} from "./contracts/VictimVault.sol";
import {VulnVault} from "./contracts/VulnVault.sol";
import {Attacker} from "./contracts/Attacker.sol";

contract ReadOnlyReentrancy is Test {

    VictimVault victimVault;
    VulnVault vulnVault;
    Attacker attackerContract;
    address attacker = makeAddr("attacker");
    address generalUser = makeAddr("generalUser");

    function setUp() public {
        vulnVault = new VulnVault();
        victimVault = new VictimVault(address(vulnVault));
        attackerContract = new Attacker(address(vulnVault), address(victimVault));

        vm.deal(address(generalUser), 20e18);
        vm.deal(address(attackerContract), 1e18);
        

    }
    
    // source => https://github.com/Ackee-Blockchain/reentrancy-examples/blob/master/tests/test_8_read_only_reentrancy.py
    // Run it with => forge test --match-test test_readOnlyReentrancy -vvvv | grep -v  "console" | grep -v "Stop" | grep -v "Prank" | grep -v "prank"                     

    function test_readOnlyReentrancy() public {
       vm.startPrank(generalUser);
        vulnVault.deposit{value: 10e18}();
        victimVault.deposit{value: 10e18}();
       vm.stopPrank();
    
      console.log("Vault Initial Balance: %e", address(victimVault).balance);
      console.log("Attacker Initial Balance: %e", address(attackerContract).balance);

      console.log("---------------------attack---------------------");
      
      vm.prank(attacker);
      attackerContract.attack();

      console.log("Vault Final Balance:  %e", address(victimVault).balance);
      console.log("Attacker Final Balance: %e", address(attackerContract).balance);
    }
}