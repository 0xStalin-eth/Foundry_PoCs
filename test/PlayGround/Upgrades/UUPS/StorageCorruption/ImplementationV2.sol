// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ImplementationV2 is UUPSUpgradeable {
    string private constant BRIDGE_REASON = 'bridge';

    address public dsToken;
    address public dsServiceConsumer;

    mapping(uint16 wmChainId => bytes32 bridge) public bridgeAddresses;

    address public wormholeCore;
    address public executorQuoterRouter;
    address public quoterAddr;

    /// @dev ethereum: instant 200 - safe 201 - otherwise finalized
    uint8 public consistencyLevel;

    uint8 internal constant US = 1;

    // replay protection
    mapping(bytes32 vmHash => bool isConsumed) public isVaaConsumed;

    uint128 public gasLimit;

    uint128 public msgValue;

    mapping(uint16 wmChainId => bytes32 emitter) public emitterAddresses;

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
        gasLimit = 1_000_000;
        msgValue = 0;
        consistencyLevel = 201; // default: safe
    }

    function _authorizeUpgrade(address) internal override {}

}