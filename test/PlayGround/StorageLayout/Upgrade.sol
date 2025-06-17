import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Upgrade {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public total;
    address immutable TREASURY;
    address immutable BURN_ADDRESS;
    EnumerableSet.AddressSet internal stakers;
    address public owner;
}