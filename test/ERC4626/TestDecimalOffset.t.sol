//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockERC20} from "./MockERC20.sol";
import {MockVault} from "./MockVault.sol";

contract TestDecimalOffset is Test {
    using Math for uint256;

    uint256 underlyingDecimals;

    MockERC20 underlying;

    MockVault vault;

    function test_decimalOffset() public {
    //@audit => Use any of the 3 `underlying` variables defined below (one at a time) to test the computation of shares using underlyingTokens with different decimals.

    //@audit => Setting up Vault
    uint8 underlyingDecimals = 6; // USDC
    // uint8 underlyingDecimals = 8; // USDT
    // uint8 underlyingDecimals = 18; // DAI
    underlying = new MockERC20(underlyingDecimals);

    vault = new MockVault();
    vault.initialize(
      IERC20(address(underlying))
    );

    uint256 OFFSET_DECIMALS = vault.decimalOffset();

    //@audit => Alice deposits 1 full UnderlyingToken on the Vault
    uint256 depositUnderlyingAmount = 1 * (10 ** underlyingDecimals); //1e6!
    address alice = makeAddr("alice");
    underlying.mint(alice, depositUnderlyingAmount);

    vm.startPrank(alice);
    underlying.approve(address(vault), type(uint256).max);
    vault.deposit(depositUnderlyingAmount, alice);
    vm.stopPrank();

    //@audit-info => Vault received 1 full UnderlyingToken
    assertEq(underlying.balanceOf(address(vault)), depositUnderlyingAmount);
    //@audit-info => Vault shares are escaled by underlyingDecimals + OFFSET_DECIMALS
      //@audit-info => For example, USDC, vault shares would be escaled by 15 (1e15)
      //@audit-info => For example, USDT, vault shares would be escaled by 17 (1e17)
      //@audit-info => For example, DAI, vault shares would be escaled by 18 (1e27)
    assertEq(vault.balanceOf(alice), depositUnderlyingAmount * (1 * (10 ** OFFSET_DECIMALS))); //1e6 * 1e9 == 1e15
    
    uint256 vaultTotalSupply = vault.totalSupply();
    uint256 assetsInVault = underlying.balanceOf(address(vault));

    assertEq(assetsInVault, 1 * 10 ** underlyingDecimals);
    assertEq(vaultTotalSupply, assetsInVault * 10 ** OFFSET_DECIMALS);

    // console2.log("fee: ", fee);

    console2.log("vaultTotalSupply: ", vaultTotalSupply);
    console2.log("assetsInVault: ", assetsInVault);
    //@audit => minted shares for 1 full underlyingToken are escaled by OFFSET_DECIMALS more than the underlyingTkoenDecimals
        //@audit-info => For example, USDC, vault shares would be escaled by 15 (1e15)
        //@audit-info => For example, USDT, vault shares would be escaled by 17 (1e17)
        //@audit-info => For example, DAI, vault shares would be escaled by 18 (1e27)
    console2.log("totalSupply + decimalOffset" , vaultTotalSupply + 10 ** OFFSET_DECIMALS);
  }
}
