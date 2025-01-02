pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";

import { LendingProtocol } from "../../src/LendingProtocol.sol";


// contract LendingProtocolWrapper is LendingProtocol {
//   function setBalanceOf(address _account, uint256 _newValue) external {
//     balanceOf[_account] = _newValue;
//   }
// }


contract SimulateBadDebtTest is Test {
  using stdStorage for StdStorage;
  
  address alice = vm.addr(123);
  LendingProtocol vault;

  function setUp() public {
    vault = new LendingProtocol();
  }

  function test_simulateBadDebt() public {
    vm.deal(alice,10 ether);

    vm.prank(alice);
    vault.deposit{value: 1 ether}();

    assertEq(address(vault).balance, 1 ether);

    uint256 aliceBalanceBeforeBadDebt = vault.accountBalance(alice);
    assertEq(aliceBalanceBeforeBadDebt, 1 ether);

    // Foundry Documentation => https://book.getfoundry.sh/reference/forge-std/std-storage
    //@audit => Only works for public variables
    // stdstore
    // .target(address(vault))
    // .sig("balanceOf(address)")
    // .with_key(alice)
    // .checked_write(0.5 ether);

    //@audit => Works for private variables
    //@audit-info => https://book.getfoundry.sh/cheatcodes/store#description
    vm.store(address(vault), bytes32(getStorageSlotInMapping()), bytes32(uint256(0.5 ether)));

    uint256 aliceBalanceAfterBadDebt = vault.accountBalance(alice);
    assertEq(aliceBalanceAfterBadDebt, 0.5 ether);

  }

  //@audit-info => https://www.rareskills.io/post/solidity-dynamic
  function getStorageSlotInMapping() public view returns (bytes32 slot) {
      // uint256 balanceMappingSlot;

      // assembly {
      //       // `.slot` returns the state variable (balance) location within the storage slots.
      //       // In our case, balance.slot = 0
      //       balanceMappingSlot := balanceOf.slot
      // }

      //@note => Hardcoded the slot of the mapping.
      //@note => Another way to get the slot is by deploying the contract to a local chain (anvil), and, run `cast storage` to get the slot# of the variable we want to know the slot of
          /*
            cast storage 0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url http://127.0.0.1:8545
            | Name      | Type                        | Slot | Offset | Bytes | Value | Hex Value                                                          | Contract                                |
            |-----------|-----------------------------|------|--------|-------|-------|--------------------------------------------------------------------|-----------------------------------------|
            | balanceOf | mapping(address => uint256) | 0    | 0      | 32    | 0     | 0x0000000000000000000000000000000000000000000000000000000000000000 | src/LendingProtocol.sol:LendingProtocol |
          */

      //@audit => Compute the exact slot for alice on the `balanceOf` mapping (balanceOf is located at the slot 0)
      slot = keccak256(abi.encode(alice, 0));
  }
}