// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { License } from "./License.sol";

enum DelegatorStatus {
  Unknown,
  PendingAdded,
  Active,
  PendingRemoved
}

struct DelegationInfo {
  DelegatorStatus status;
  address owner;
  uint256[] tokenIDs;
}


contract StakingManager {
    License public licenseContract;
    mapping(bytes32 delegationID => DelegationInfo) delegations;
    mapping(uint256 licenseTokenID => bytes32 delegationID) tokenLockedBy;
    mapping(address staker => uint256 stakedWeight) public stakersWeight;
    uint256 validationID;

    error TokenAlreadyLocked(uint256 tokenID);
    error UnauthorizedOwner();
    error InvalidDelegatorStatus(DelegatorStatus status);

    constructor(address licenseContract_) {
        licenseContract = License(licenseContract_);
    }

    function initiateDelegatorRegistration(uint256[] calldata tokenIDs) public returns (bytes32) {
        validationID++;
        return _initiateDelegatorRegistration(validationID, msg.sender, tokenIDs);
    }

    function _initiateDelegatorRegistration(
        uint256 validationID,
        address owner,
        uint256[] calldata tokenIDs
    ) internal returns (bytes32) {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (licenseContract.ownerOf(tokenIDs[i]) != owner) {
                revert UnauthorizedOwner();
            }
        }
        bytes32 delegationID = keccak256(abi.encodePacked(validationID));

        _lockTokens(delegationID, tokenIDs);

        DelegationInfo storage newDelegation = delegations[delegationID];
        newDelegation.owner = owner;
        newDelegation.tokenIDs = tokenIDs;
        newDelegation.status = DelegatorStatus.PendingAdded;

        return delegationID;
    }

    function completeDelegatorRegistration(bytes32 delegationID) public {
        DelegationInfo storage delegation = delegations[delegationID];

        if (delegation.status != DelegatorStatus.PendingAdded) {
            revert InvalidDelegatorStatus(delegation.status);
        }

        delegation.status = DelegatorStatus.Active;

        stakersWeight[delegation.owner] += uint32(delegation.tokenIDs.length);
    }

    function initiateDelegatorRemoval(bytes32 delegationIDs) public {
        DelegationInfo storage delegation = delegations[delegationIDs];

        if (delegation.owner != msg.sender) {
            revert UnauthorizedOwner();
        }

        if (delegation.status != DelegatorStatus.Active) {
            revert InvalidDelegatorStatus(delegation.status);
        }

        delegation.status = DelegatorStatus.PendingRemoved;

        stakersWeight[delegation.owner] -= uint32(delegation.tokenIDs.length);  
    }

    function completeDelegatorRemoval(bytes32 delegationID) external {
        DelegationInfo storage delegation = delegations[delegationID];
        if (delegation.status != DelegatorStatus.PendingRemoved) {
            revert InvalidDelegatorStatus(delegation.status);
        }

        _unlockTokens(delegationID, delegation.tokenIDs);
    }


    function _lockTokens(bytes32 delegationID, uint256[] memory tokenIDs) internal {
        address owner;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            licenseContract.ownerOf(tokenID);
            if (tokenLockedBy[tokenID] != bytes32(0)) revert TokenAlreadyLocked(tokenID);
            tokenLockedBy[tokenID] = delegationID;
        }
    }

    function _unlockTokens(bytes32 delegationID, uint256[] memory tokenIDs) internal {
        DelegationInfo storage stake = delegations[delegationID];
        address owner = stake.owner;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tokenLockedBy[tokenIDs[i]] = bytes32(0);
        }
    }

    function getTokenLockedBy(uint256 tokenID) external view returns (bytes32) {
        return tokenLockedBy[tokenID];
    }

}