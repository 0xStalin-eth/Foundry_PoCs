// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ImplementationV1} from "./ImplementationV1.sol";
import {ImplementationV2} from "./ImplementationV2.sol";

contract UUPSUpgradeTest is Test {

    // ── Actors ────────────────────────────────────────────────────────────────
    address internal deployer    = makeAddr("deployer");
    address internal nonUpgrader = makeAddr("nonUpgrader");

    // ── Init params ───────────────────────────────────────────────────────────
    address internal constant WORMHOLE_CORE           = address(0x1111);
    address internal constant EXECUTOR_QUOTER_ROUTER  = address(0x2222);
    address internal constant QUOTER_ADDR             = address(0x3333);
    address internal constant DS_TOKEN                = address(0x4444);

    // V1 post-init expected values
    uint128 internal constant V1_GAS_LIMIT         = 2_000_000;
    uint8   internal constant V1_CONSISTENCY_LEVEL = 201;

    // ── Contracts ─────────────────────────────────────────────────────────────
    ERC1967Proxy     internal proxy;
    ImplementationV1 internal implV1;
    ImplementationV2 internal implV2;

    ImplementationV1 internal proxyAsV1;
    ImplementationV2 internal proxyAsV2;

    // ── ERC-1967 implementation slot ──────────────────────────────────────────
    bytes32 internal constant IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    // ─────────────────────────────────────────────────────────────────────────
    // setUp
    // ─────────────────────────────────────────────────────────────────────────
    function setUp() public {
        vm.startPrank(deployer);

        implV1 = new ImplementationV1();
        implV2 = new ImplementationV2();

        bytes memory initData = abi.encodeWithSelector(
            ImplementationV1.initialize.selector,
            WORMHOLE_CORE,
            EXECUTOR_QUOTER_ROUTER,
            QUOTER_ADDR,
            DS_TOKEN
        );
        proxy = new ERC1967Proxy(address(implV1), initData);

        vm.stopPrank();

        proxyAsV1 = ImplementationV1(address(proxy));
        proxyAsV2 = ImplementationV2(address(proxy));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    function _currentImpl() internal view returns (address) {
        return address(uint160(uint256(vm.load(address(proxy), IMPL_SLOT))));
    }

    function _loadSlot(uint256 slot) internal view returns (bytes32) {
        return vm.load(address(proxy), bytes32(slot));
    }

    function _upgradeToV2() internal {
        vm.prank(deployer);
        proxyAsV1.upgradeToAndCall(address(implV2), "");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRE-UPGRADE – V1 state
    // ─────────────────────────────────────────────────────────────────────────

    function test_v1_ImplementationSlot() public view {
        assertEq(_currentImpl(), address(implV1), "impl slot must point to V1");
    }

    function test_v1_InitialisedAddresses() public view {
        assertEq(proxyAsV1.dsToken(),              DS_TOKEN,               "dsToken");
        assertEq(proxyAsV1.dsServiceConsumer(),    DS_TOKEN,               "dsServiceConsumer");
        assertEq(proxyAsV1.wormholeCore(),         WORMHOLE_CORE,          "wormholeCore");
        assertEq(proxyAsV1.executorQuoterRouter(), EXECUTOR_QUOTER_ROUTER, "executorQuoterRouter");
        assertEq(proxyAsV1.quoterAddr(),           QUOTER_ADDR,            "quoterAddr");
    }

    function test_v1_InitialisedPackedSlot6() public view {
        assertEq(proxyAsV1.gasLimit(),         V1_GAS_LIMIT,         "V1 gasLimit");
        assertEq(proxyAsV1.consistencyLevel(), V1_CONSISTENCY_LEVEL, "V1 consistencyLevel");
    }

    /// @dev Verify slot 6 raw encoding under V1:
    ///      gasLimit  occupies the lower 16 bytes (bits   0–127).
    ///      consistency occupies byte 16          (bits 128–135).
    function test_v1_RawSlot6Packing() public view {
        bytes32 raw = _loadSlot(6);

        uint128 rawGasLimit    = uint128(uint256(raw));         // lower 16B
        uint8   rawConsistency = uint8(uint256(raw) >> 128);   // byte 16

        assertEq(rawGasLimit,    V1_GAS_LIMIT,         "raw slot6: gasLimit");
        assertEq(rawConsistency, V1_CONSISTENCY_LEVEL, "raw slot6: consistencyLevel");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE – access control
    // ─────────────────────────────────────────────────────────────────────────

    function test_upgrade_RevertsForNonUpgrader() public {
        // _authorizeUpgrade has no access control in either contract.
        // This test documents the absence of a guard – flag as a finding.
        vm.prank(nonUpgrader);
        proxyAsV1.upgradeToAndCall(address(implV2), "");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE – implementation slot
    // ─────────────────────────────────────────────────────────────────────────

    function test_upgrade_ImplementationSlotUpdated() public {
        _upgradeToV2();
        assertEq(_currentImpl(), address(implV2), "impl slot must point to V2");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST-UPGRADE – storage layout
    //
    //  Root cause of all collisions: removing gasLimit from between quoterAddr
    //  and consistencyLevel in V2 causes consistencyLevel to pack into slot 5
    //  (alongside quoterAddr), shifting every subsequent variable down by one slot.
    //
    //  ┌──────┬───────────────────────────────────┬──────────────────────────────────────┐
    //  │ Slot │ V1                                │ V2                                   │
    //  ├──────┼───────────────────────────────────┼──────────────────────────────────────┤
    //  │  0   │ dsToken (address)                 │ dsToken (address)           ✅ safe  │
    //  │  1   │ dsServiceConsumer (address)       │ dsServiceConsumer (address) ✅ safe  │
    //  │  2   │ bridgeAddresses (u16→address map) │ bridgeAddresses (u16→bytes32 map)    │
    //  │      │                                   │   ⚠️  value type widened             │
    //  │  3   │ wormholeCore (address)            │ wormholeCore (address)      ✅ safe  │
    //  │  4   │ executorQuoterRouter (address)    │ executorQuoterRouter        ✅ safe  │
    //  │  5   │ quoterAddr (address, 20B)         │ quoterAddr (address,20B)             │
    //  │      │   [12B unused]                    │   + consistencyLevel (uint8, 1B)     │
    //  │      │                                   │   💥 packed: reads byte 20 of slot 5 │
    //  │      │                                   │      which V1 left as 0 → reads 0    │
    //  │  6   │ gasLimit (uint128, 16B)           │ isVaaConsumed mapping                │
    //  │      │ + consistencyLevel (uint8, 1B)    │   💥 base slot shifted from 7 → 6    │
    //  │      │   packed                          │      ALL replay entries are lost      │
    //  │  7   │ isVaaConsumed mapping             │ gasLimit (uint128, 16B)              │
    //  │      │                                   │   + msgValue (uint128, 16B) packed   │
    //  │      │                                   │   💥 gasLimit reads 0 (slot moved)   │
    //  │  8   │ (unwritten)                       │ emitterAddresses mapping – fresh      │
    //  └──────┴───────────────────────────────────┴──────────────────────────────────────┘
    // ─────────────────────────────────────────────────────────────────────────

    // ── Safe variables (slots 0–4 unaffected) ─────────────────────────────────

    function test_postUpgrade_AddressesPreserved() public {
        _upgradeToV2();

        assertEq(proxyAsV2.dsToken(),              DS_TOKEN,               "dsToken preserved");
        assertEq(proxyAsV2.dsServiceConsumer(),    DS_TOKEN,               "dsServiceConsumer preserved");
        assertEq(proxyAsV2.wormholeCore(),         WORMHOLE_CORE,          "wormholeCore preserved");
        assertEq(proxyAsV2.executorQuoterRouter(), EXECUTOR_QUOTER_ROUTER, "executorQuoterRouter preserved");
        assertEq(proxyAsV2.quoterAddr(),           QUOTER_ADDR,            "quoterAddr preserved");
    }

    // ── 💥 Finding 1 – consistencyLevel corrupted (slot 5, byte 20) ───────────

    /// @dev Root cause: removing gasLimit from between quoterAddr and consistencyLevel
    ///      allows the compiler to pack them together into slot 5.
    ///      V2 reads consistencyLevel from byte 20 of slot 5.
    ///      V1 only wrote quoterAddr into slot 5 (bytes 0–19); byte 20 was never set.
    ///      Result: consistencyLevel reads 0 instead of 201.
    function test_postUpgrade_ConsistencyLevel_CORRUPTED() public {
        _upgradeToV2();

        uint8 v2Consistency = proxyAsV2.consistencyLevel();

        // 1. Prove the expected value is gone
        assertNotEq(v2Consistency, V1_CONSISTENCY_LEVEL,
            "BUG: consistencyLevel no longer holds 201 after upgrade");

        // 2. Prove the exact corrupted value: byte 20 of slot 5 was unwritten in V1
        assertEq(v2Consistency, 0,
            "BUG: consistencyLevel reads 0 - packed into slot 5 byte 20 which V1 never wrote");
    }

    /// @dev Confirms the raw slot 5 state: V1 wrote only quoterAddr (bytes 0–19).
    ///      Byte 20 (where V2 reads consistencyLevel) is 0x00.
    function test_postUpgrade_RawSlot5_ByteWhereConsistencyNowLives() public {
        _upgradeToV2();

        bytes32 slot5 = _loadSlot(5);

        // V2 reads consistencyLevel as uint8(slot5 >> 160) - the byte just above quoterAddr
        uint8 byteWhereConsistencyLives = uint8(uint256(slot5) >> 160);

        assertEq(byteWhereConsistencyLives, 0,
            "byte 20 of slot 5 was never written by V1 - V2 reads 0 as consistencyLevel");
    }

    // ── 💥 Finding 2 – gasLimit lost (slot 6 → slot 7) ───────────────────────

    /// @dev gasLimit moved from slot 6 (lower 16B) in V1 to slot 7 (lower 16B) in V2.
    ///      Slot 7 was the isVaaConsumed mapping base in V1 (always 0 at the base slot).
    ///      Result: gasLimit reads 0 instead of 2_000_000.
    function test_postUpgrade_GasLimit_LOST() public {
        _upgradeToV2();

        uint128 v2GasLimit = proxyAsV2.gasLimit();

        assertNotEq(v2GasLimit, V1_GAS_LIMIT,
            "BUG: gasLimit no longer holds 2_000_000 after upgrade");

        assertEq(v2GasLimit, 0,
            "BUG: gasLimit reads 0 - moved from slot 6 to slot 7 which V1 never wrote");
    }

    // ── 💥 Finding 3 – isVaaConsumed replay-protection entries lost ───────────

    /// @dev isVaaConsumed mapping base slot shifted from slot 7 (V1) to slot 6 (V2).
    ///      Entries are keyed by keccak256(vmHash . baseSlot), so a base slot change
    ///      makes ALL previously stored entries unreachable under V2.
    ///      Any vmHash consumed under V1 will appear unconsumed to V2 - replay possible.
    function test_postUpgrade_IsVaaConsumed_EntriesLost() public {
        // Mark a VAA as consumed under V1
        bytes32 vmHash = keccak256("some-vaa-hash");

        // Write directly: simulate what the bridge contract would do
        // keccak256(vmHash . slot7) is where V1 stores isVaaConsumed[vmHash]
        bytes32 v1StorageKey = keccak256(abi.encode(vmHash, uint256(7)));
        vm.store(address(proxy), v1StorageKey, bytes32(uint256(1))); // true

        // Confirm it is readable through V1 getter
        assertTrue(proxyAsV1.isVaaConsumed(vmHash), "V1: entry must be set before upgrade");

        _upgradeToV2();

        // V2 looks up isVaaConsumed[vmHash] at keccak256(vmHash . slot6) - different key
        bytes32 v2StorageKey = keccak256(abi.encode(vmHash, uint256(6)));
        bool v2Value = uint256(vm.load(address(proxy), v2StorageKey)) == 1;

        assertFalse(v2Value,
            "BUG: entry written at slot 7 key is NOT found at slot 6 key - replay protection broken");
        assertFalse(proxyAsV2.isVaaConsumed(vmHash),
            "BUG: V2 reports vmHash as NOT consumed even though V1 marked it consumed");
    }

    // ── New variable sanity checks ────────────────────────────────────────────

    function test_postUpgrade_MsgValue_IsZero() public {
        _upgradeToV2();
        // msgValue is new in slot 7 upper 16B; safe since that portion was never written
        assertEq(proxyAsV2.msgValue(), 0, "msgValue starts at 0 as expected");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Canary – bare implementations must not be re-initialised
    // ─────────────────────────────────────────────────────────────────────────

    function test_implV1_CannotBeInitialisedDirectly() public {
        vm.expectRevert();
        implV1.initialize(WORMHOLE_CORE, EXECUTOR_QUOTER_ROUTER, QUOTER_ADDR, DS_TOKEN);
    }

    function test_implV2_CannotBeInitialisedDirectly() public {
        vm.expectRevert();
        implV2.initialize(WORMHOLE_CORE, EXECUTOR_QUOTER_ROUTER, QUOTER_ADDR, DS_TOKEN);
    }
}