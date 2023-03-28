// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

contract Raffle {

    struct RaffleInfo {
        address winner;
        uint8 ticketsCount;
        uint88 totalPrize;
        address[] participants;
    }

    address public owner;   // 0x00 20 bytes
    uint256 public price;  // 0x01   22 bytes
    uint256 public maxTickets; // 0x02  
    uint256 public userMaxTickets; // 0x03
    uint256 public currentRaffleId; // 0x04

    mapping(address => mapping(uint256 => uint256)) public userTickets; // 0x05

    mapping(uint256 => RaffleInfo) public raffle;   // 0x06 and 0x07

    event Registered(address indexed user, uint256 ticketsCount);

    error NotOwner();
    error NotEnougthEther();
    error MaxTicketsReached();

    constructor() {
        owner = msg.sender;
        price = 0.5 ether;
        maxTickets = 20;
        userMaxTickets = 3;
        currentRaffleId = 1;

        
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function enter(uint8 qty) public payable {
        RaffleInfo storage currentRaffle = raffle[currentRaffleId];

        if (currentRaffle.ticketsCount + qty > maxTickets) revert MaxTicketsReached();
        if (userTickets[msg.sender][currentRaffleId] + qty > userMaxTickets) revert MaxTicketsReached();
        if (msg.value < price * qty) revert NotEnougthEther();

        for (uint i = 0; i < qty; i++) {
            currentRaffle.participants.push(msg.sender);
        }

        currentRaffle.ticketsCount += qty;
        currentRaffle.totalPrize += uint88(price * qty);
        userTickets[msg.sender][currentRaffleId] += qty;

        emit Registered(msg.sender, qty);
    }

    function getParticipants(uint256 raffleId) external view returns (address[] memory) {
        return raffle[raffleId].participants;
    }


    function enterYul(uint8 qty) public payable {
        assembly {
            // access to raffle[raffleId].ticketsCount
            // keccack256(mapping_key . mapping_slot) + i
            // keccak256(sload(0x04) . 0x06) + 0 // 0 because ticketsCount is bitpacked with address and totalPrize
            mstore(0x00, currentRaffleId.slot) // store raffle id 
            mstore(0x20, raffle.slot) // map slot location
            let raffleSlot := keccak256(0, 0x40)
            let raffleInfo := sload(raffleSlot)
            
            //        uint88 totalPrize        uint8 ticketsCount              address winner
            // before 0003000000000000000000         08            019f82740818b6f37B7175de42702FE9359ea7Da
            // get addresss
            // mask   0000000000000000000000         00            FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            // after  0000000000000000000000         00            019f82740818b6f37B7175de42702FE9359ea7Da
            // get ticketsCount
            // >> 160    0000000000000000000000000000000000000000  0003000000000000000000  08
            // mask      0000000000000000000000000000000000000000  0000000000000000000000  FF
            // get totalprize
            // << 168    00     0000000000000000000000000000000000000000   0003000000000000000000
            let address_mask := mul(0x01, 0xa0)
            let user_address := and(address_mask, raffleInfo)
            let tickets_count := and(0xff, shr(0xa0, raffleInfo))
            let total_prize := shl(0xa1, raffleInfo)
            
            let memMaxTickets := sload(maxTickets.slot)
            if lt(memMaxTickets, add(qty, tickets_count)) { revert(0,0) }
            
            // userTickets[msg.sender] => keccak256()
            // access to userTickets[msg.sender][currentRaffleId]
            // keccak256(mapping_key . keccak256(mapping_key . mapping_slot))
            // keccak256(raffleId . keccak(msg.sender . userTicketsSlot))

            mstore(0x00, caller())
            mstore(0x20, userTickets.slot)
            let firstStep := keccak256(0x00, 0x40)

            mstore(0x00, firstStep)
            mstore(0x20, currentRaffleId.slot)
            let finalSlot := keccak256(0x00, 0x20)

            let userBalance := sload(finalSlot)

            let memUserMaxTickets := sload(userMaxTickets.slot)
            if lt(memUserMaxTickets, add(userBalance, qty)) { revert(0,0) }
            
            let cost := mul(sload(price.slot), qty)
            if lt(callvalue(), cost) { revert(0,0) }
            
            let arraySlot := add(raffleSlot, 0x01) // 
            let currentArrayLength := sload(arraySlot) // 
            sstore(arraySlot, add(currentArrayLength, qty)) // store the new array length
            for { let i := 0 } lt(i, qty) { i := add(i, 0x01)} {
                // compute the location of current element in array
                // keccak256(arrayLength + i + 1) 
                let elementSlot := keccak256(add(currentArrayLength, add(i, 0x01)), 0x20)
                sstore(elementSlot, caller())
            }


        }
    }
}