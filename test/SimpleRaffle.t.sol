// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface SimpleRaffle {
    function owner() external view returns (address);
    
    function createRaffle() external;
    function drawWinner() external returns (address);

    function winnerOf(uint256) external view returns (address);
    function totalPrizeOf(uint256) external view returns (uint256);

    function userTicketsQuantity(address,uint256) external view returns (uint256);
    function raffleTicketsQuantity(uint256) external view returns (uint256);
}

contract SimpleRaffleTest is Test {

    // The System under Test.
    SimpleRaffle sut;

    function setUp() public {
        address impl = HuffDeployer.deploy("SimpleRaffle");
        sut = SimpleRaffle(impl);
    }

    function testDeploymentOwnerValue() public {
        assertEq(sut.owner(), address(this));
    }


}
