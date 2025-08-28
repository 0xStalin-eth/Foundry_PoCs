// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract Math is Test {
    function test_Substract() external pure {
        uint256 originalAssetDepositNet = 100e18;
        uint256 assetDepositNet = originalAssetDepositNet;
        uint256 yieldAssetValue = 10e18;
        uint256 yieldFeeAssetValue = 5e18;

        assetDepositNet -= yieldAssetValue + yieldFeeAssetValue;

        assertEq(assetDepositNet, originalAssetDepositNet - (yieldAssetValue + yieldFeeAssetValue));
    }

}