//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  uint8 decimals_;
  constructor(uint8 _decimals) ERC20("MOCK", "MOCK") {
    decimals_ = _decimals;
  }

  function mint(address receiver, uint256 amount) external {
    _mint(receiver, amount);
  }

  function decimals() public view override returns (uint8) {
    return decimals_;
  }
}