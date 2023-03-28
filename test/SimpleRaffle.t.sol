// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Raffle} from "src/Raffle.sol";
import {Utilities} from "test/utils/Utilities.sol";

interface SimpleRaffle {
    function owner() external view returns (address);
    function price() external view returns (uint256);

    function createRaffle() external;
    function drawWinner() external returns (address);

    function winnerOf(uint256) external view returns (address);
    function totalPrizeOf(uint256) external view returns (uint256);

    function userTicketsQuantity(address,uint256) external view returns (uint256);
    function raffleTicketsQuantity(uint256) external view returns (uint256);
}

contract SimpleRaffleTest is Test {

    Utilities internal utils;
    SimpleRaffle internal raffleHuff;
    Raffle internal raffle;
    address[] internal users;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        address impl = HuffDeployer.deploy("SimpleRaffle");
        raffleHuff = SimpleRaffle(impl);
        raffle = new Raffle();
    }

    function testDeploymentOwnerValue() public {
        assertEq(raffleHuff.owner(), address(this));
        assertEq(raffleHuff.price(), 0.5 ether);
        assertEq(raffle.owner(), address(this));
    }

    function testEnterRaffle() public {
        vm.prank(users[0]);
        raffle.enter{value: 1 ether}(2);
        raffle.enterYul{value: 1 ether}(2);
        address[] memory participants = raffle.getParticipants(1);
        assertEq(participants.length, 2);
    }
}
