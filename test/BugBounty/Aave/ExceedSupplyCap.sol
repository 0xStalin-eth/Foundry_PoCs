// https://polygon-mainnet.g.alchemy.com/v2/kw-QtOJ-qDdBcl4QOBFme3ZhJEbjRkF5

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IPool} from "./interfaces/IPool.sol";
import {IAToken} from "./interfaces/IAToken.sol";
import {DataTypes} from './interfaces/DataTypes.sol';

//@audit-info => This PoC was coded to work on Polyong PoS
contract ExceedSupplyCap is Test {
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;

    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;

    address alice = address(0x1);
    address whale = address(0xF977814e90dA44bFA03b6295A0616a897441aceC);
    IERC20 public constant USDC = IERC20(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);
    IAToken public constant aPolUSDCn = IAToken(0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD);
    IPool public constant USDC_POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    function setUp() public {
      // transfer from a whale to alice
      vm.prank(whale);
      USDC.transfer(alice, 20_000_000e6);
    }

    function getSupplyCap(
      DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
      return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    function getDecimals(
      DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
      return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    // anvil --fork-url https://polygon-mainnet.g.alchemy.com/v2/<ALCHEMY_KEY>
    // forge test --match-test test_ExceedSupplyCap --fork-url {YOUR_RPC}.
      // When working with anvil, {YOUR_RPC} would be => 127.0.0.1:8545
    function test_ExceedSupplyCap() public {

      address[] memory mintAssets = new address[](1);
      mintAssets[0] = address(USDC);
      
      USDC_POOL.mintToTreasury(mintAssets);
      

      uint256 totalSupply = aPolUSDCn.totalSupply();
      uint256 scaledTotalSupply = aPolUSDCn.scaledTotalSupply();

      console2.log("totalSupply: ", totalSupply);
      console2.log("scaledTotalSupply: ", scaledTotalSupply);

      DataTypes.ReserveData memory reserveData = USDC_POOL.getReserveData(address(USDC));

      assertEq(reserveData.aTokenAddress, address(aPolUSDCn));
      assertEq(reserveData.accruedToTreasury, 0);

      uint256 currentSupplyCap = getSupplyCap(reserveData.configuration);
      console2.log("currentSupplyCap: ", currentSupplyCap);

      uint256 currentSupplyCapWithTokenDecimals = currentSupplyCap * (10 ** getDecimals(reserveData.configuration));
      console2.log("currentSupplyCapWithTokenDecimals: ", currentSupplyCapWithTokenDecimals);

      assertEq(currentSupplyCapWithTokenDecimals, 50_000_000 * 10**6);

      uint256 amountToReachSupplyCap = currentSupplyCapWithTokenDecimals - totalSupply;
      console2.log("amountToReachSupplyCap: ", amountToReachSupplyCap);

      vm.startPrank(alice);

      USDC.approve(address(USDC_POOL), type(uint256).max);

      //@audit-ok => If trying to supply more than the amountToReachSupplyCap, execution reverts :)
      USDC_POOL.supply(address(USDC), 16_071_500e6, address(alice), 0);

      uint256 totalSupplyAfter = aPolUSDCn.totalSupply();
      uint256 scaledTotalSupplyAfter = aPolUSDCn.scaledTotalSupply();
      console2.log("totalSupplyAfter: ", totalSupplyAfter);
      console2.log("scaledTotalSupplyAfter: ", scaledTotalSupplyAfter);

      vm.stopPrank();
    }
}