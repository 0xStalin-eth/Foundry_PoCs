// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract Memory is Test {
    struct Struct_Metadata {
        uint256 stableValueGross;
        uint256 stableValueNet;

        uint256 depositfeeAmount;
        uint256 insurancefeeAmount;

    }
    function test_StructInMemoryIsNotOverridenFromAnInternalFunction() external {
        Struct_Metadata memory MetaData;
        MetaData.stableValueGross = 100e18;
        //@audit-info => Rest of values are not defaulted to 0
        //@audit-info => https://claude.ai/share/3f8ec2b4-a954-4f13-bcde-1017b64a5657
        MetaData = calculateFees(MetaData);
        MetaData.stableValueNet = MetaData.stableValueGross - (MetaData.depositfeeAmount + MetaData.insurancefeeAmount);

        assertEq(MetaData.stableValueGross, 100e18);
        assertEq(MetaData.depositfeeAmount, 10e18);
        assertEq(MetaData.insurancefeeAmount, 10e18);
        assertEq(MetaData.stableValueNet, MetaData.stableValueGross - (MetaData.depositfeeAmount + MetaData.insurancefeeAmount));
    }

    function calculateFees(
        Struct_Metadata memory data
    ) internal pure returns (Struct_Metadata memory) {
        data.depositfeeAmount = 10e18;
        data.insurancefeeAmount = 10e18;
        return data;
    }

}