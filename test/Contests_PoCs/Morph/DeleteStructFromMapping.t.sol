pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

library RateLimiter {
    struct TokenBucket {
        uint128 tokens; // ──────╮ Current number of tokens that are in the bucket.
        uint32 lastUpdated; //   │ Timestamp in seconds of the last token refill, good for 100+ years.
        bool isEnabled; // ──────╯ Indication whether the rate limiting is enabled or not
        uint128 capacity; // ────╮ Maximum number of tokens that can be in the bucket.
        uint128 rate; // ────────╯ Number of tokens per second that the bucket is refilled.
    }
}

contract Delete {
    using RateLimiter for RateLimiter.TokenBucket;

    struct RemoteChainConfig {
        // RateLimiter.TokenBucket outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
        bytes remotePoolAddress; // Address of the remote pool, ABI encoded in the case of a remote EVM chain.
        bytes remoteTokenAddress; // Address of the remote token, ABI encoded in the case of a remote EVM chain.
    }
    
    mapping(uint64 remoteChainSelector => RemoteChainConfig) public s_remoteChainConfigs;

    function setRemoteChainConfigs() external {
        s_remoteChainConfigs[5] = RemoteChainConfig({
          // outboundRateLimiterConfig: RateLimiter.TokenBucket({
          //   rate: 100,
          //   capacity: 100,
          //   tokens: 100,
          //   lastUpdated: uint32(block.timestamp),
          //   isEnabled: true
          // }),
          remotePoolAddress: abi.encode(0x10),
          remoteTokenAddress: abi.encode(0x10)
        });
    }

    function getRemoteChainConfigs(uint64 remoteChainSelector) public view returns (RemoteChainConfig memory) {
        return s_remoteChainConfigs[remoteChainSelector];
    }

    function deleteMapping() external {
        delete s_remoteChainConfigs[5];
    }

}


contract TrustedAddressTest is Test, Delete {
  function test_deleteStructFromMapping() public {
    Delete testContract = new Delete();
    RemoteChainConfig memory stateBefore = testContract.getRemoteChainConfigs(5);
    console2.log("s_remoteChainConfigs - BEFORE: " , vm.toString(keccak256(abi.encodePacked(stateBefore.remotePoolAddress, stateBefore.remoteTokenAddress))));

    testContract.setRemoteChainConfigs();
    RemoteChainConfig memory stateAfter = testContract.getRemoteChainConfigs(5);
    console2.log("s_remoteChainConfigs - AFTER: " , vm.toString(keccak256(abi.encodePacked(stateAfter.remotePoolAddress, stateAfter.remoteTokenAddress))));

    testContract.deleteMapping();
    RemoteChainConfig memory afterDelete = testContract.getRemoteChainConfigs(5);
    console2.log("s_remoteChainConfigs - AFTER: " , vm.toString(keccak256(abi.encodePacked(afterDelete.remotePoolAddress, afterDelete.remoteTokenAddress))));

  }
}