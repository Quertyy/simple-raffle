// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../HuffDeployer.sol";

interface Number {
    function setNumber(uint256) external;
    function getNumber() external returns (uint256);
}

interface Constructor {
    function getArgOne() external returns (address);
    function getArgTwo() external returns (uint256);
}

contract HuffDeployerTest is Test {
    Number number;
    Constructor structor;

    function setUp() public {
        number = Number(HuffDeployer.deploy("test/contracts/Number"));

        // Showcase alignment of address
        bytes memory first_arg = abi.encode(address(0x420));
        // abi encoded first_arg should equal the below 32 byte slot
        // "0000000000000000000000004200000000000000000000000000000000000000"

        // Create Constructor
        structor = Constructor(HuffDeployer.deploy_with_args(
            "test/contracts/Constructor",
            bytes.concat(first_arg, abi.encode(uint256(0x420)))
        ));
    }

    function testArgOne() public {
        assertEq(address(0x420), structor.getArgOne());
    }

    function testArgTwo() public {
        assertEq(uint256(0x420), structor.getArgTwo());
    }

    function testBytecode() public {
        bytes memory b = bytes(hex"60003560e01c80633fb5c1cb1461001c578063f2c9ecd814610023575b6004356000555b60005460005260206000f3");
        assertEq(getCode(address(number)), b);
    }

    function getCode(address who) internal view returns (bytes memory o_code) {
        /// @solidity memory-safe-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(who)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(who, add(o_code, 0x20), 0, size)
        }
    }

    function testSet(uint256 num) public {
        number.setNumber(num);
        assertEq(num, number.getNumber());
    }
}