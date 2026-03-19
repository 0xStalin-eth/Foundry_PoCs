// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ImplementationV1 is UUPSUpgradeable{
    string private constant BRIDGE_REASON = 'bridge';

    address public dsToken;
    address public dsServiceConsumer;

    mapping(uint16 chainId => address bridge) public bridgeAddresses;

    address public wormholeCore;
    address public executorQuoterRouter;

    address public quoterAddr;
    uint128 public gasLimit;
    /// @dev ethereum: instant 200 - safe 201 - otherwise finalized
    uint8 public consistencyLevel;
    uint8 internal constant US = 1;

    // replay protection
    mapping(bytes32 vmHash => bool isConsumed) public isVaaConsumed;

    function initialize(
        address _wormholeCore,
        address _executorQuoterRouter,
        address _quoterAddr,
        address _dsToken
    ) public onlyProxy initializer {
        dsToken = _dsToken;
        dsServiceConsumer = _dsToken;
        wormholeCore = _wormholeCore;
        executorQuoterRouter = _executorQuoterRouter;
        quoterAddr = _quoterAddr;
        gasLimit = 2_000_000;
        consistencyLevel = 201; // default: safe
    }

    function _authorizeUpgrade(address) internal override {}

}