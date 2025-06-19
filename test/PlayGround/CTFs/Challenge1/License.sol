// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IStakingManager {
  function getTokenLockedBy(uint256 tokenId) external view returns (bytes32);
}

contract License is ERC721 {
    address admin;
    uint256 private _nextTokenId;
    address stakingManager;

    error ZeroAddress();
    error LicenseStakedError();

    constructor(address admin_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        admin = admin_;
    }

    function mint(address to) public returns (uint256) {
        require(msg.sender == admin, "Only admin can mint new Licenses");
        require(stakingManager != address(0), "Can't mint until stakingManager is set");
        if (to == address(0)) revert ZeroAddress();
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setStakingManager(address stakingManager_) public {
        require(msg.sender == admin, "Only admin");
        stakingManager = stakingManager_;
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        returns (address)
    {
        // Early return for mint/burn operations
        if (auth == address(0) || to == address(0)) {
        return super._update(to, tokenId, auth);
        }

        // Check staking lock for normal transfers
        if (stakingManager != address(0)) {
            bytes32 lockId = IStakingManager(stakingManager).getTokenLockedBy(tokenId);
            if (lockId != bytes32(0)) {
                revert LicenseStakedError();
            }
        }

        return super._update(to, tokenId, auth);
    }
}