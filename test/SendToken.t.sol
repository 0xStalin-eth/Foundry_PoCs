// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// ERC-20 interface for interacting with the USDC token
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

// TokenTransferTest is a contract that sets up and runs the test
contract TokenTransferTest is Test {
    IERC20 usdc; // Interface instance for USDC
    address whale = 0x47c031236e19d024b42f8AE6780E44A573170703; // Polygon's ERC20 Bridge contract address on Ethereum Mainnet, used as a whale account
    address recipient = 0xFbAD768340a24E06384591537d7D2F80693d6aDB; // Vitalik's (vitalik.eth) address, used as the recipient
    address usdcAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // USDC contract address on Ethereum Mainnet

    // setUp function runs before each test, setting up the environment
    function setUp() public {
        usdc = IERC20(usdcAddress); // Initialize the USDC contract interface

        // Impersonate the whale account for testing
        vm.startPrank(whale);
    }

    // testTokenTransfer function tests the transfer of USDC from the whale account to the recipient
    function testTokenTransfer() public {
        uint256 initialBalance = usdc.balanceOf(recipient); // Get the initial balance of the recipient
        uint8 decimals = usdc.decimals(); // Get the decimal number of USDC
        uint256 transferAmount = 1000000 * 10 ** decimals; // Set the amount of USDC to transfer (1 million tokens, with 6 decimal places)

        console.log("Recipient's initial balance: ", initialBalance); // Log the initial balance to the console

        // Perform the token transfer from the whale to the recipient
        usdc.transfer(recipient, transferAmount);

        uint256 finalBalance = usdc.balanceOf(recipient); // Get the final balance of the recipient

        console.log("Recipient's final balance: ", finalBalance); // Log the final balance to the console

        // Verify that the recipient's balance increased by the transfer amount
        assertEq(finalBalance, initialBalance + transferAmount, "Token transfer failed");

        vm.stopPrank(); // Stop impersonating the whale account
    }

    //@audit => even though the test is running on a local fork, the changes to the state on the previous test are not preserved, when running this test, the recipient's balance is the same as the initial balance before doing the transfer!
    function testContinuation() public {
      uint256 balanceAfterRunningTransfer = usdc.balanceOf(recipient);
      uint8 decimals = usdc.decimals();
      console.log(balanceAfterRunningTransfer);
      assert(balanceAfterRunningTransfer >= 1000000 * 10 ** decimals);
    }
}