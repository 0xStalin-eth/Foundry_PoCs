
//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626Upgradeable, IERC20, IERC20Metadata, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";


contract MockVault is ERC4626Upgradeable {
  using Math for uint256;

  uint8 public constant decimalOffset = 9;

  function initialize(
      IERC20 baseAsset_
  ) external initializer {
    __ERC4626_init(baseAsset_);
  }

  function deposit(
      uint256 assets_,
      address receiver_
  ) public override returns (uint256 shares) {
    // Calculate the net shares to mint for the deposited assets
    shares = _convertToShares(assets_, Math.Rounding.Floor);

    _mint(receiver_, shares);

    // Transfer the assets from the sender to the vault
    IERC20(asset()).transferFrom(msg.sender, address(this), assets_);
  }

  function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
    return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** decimalOffset, rounding);
  }

  function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {
    shares = assets.mulDiv(totalSupply() + 10 ** decimalOffset, totalAssets() + 1, rounding);
  }

}