// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LotteryContract {

    struct Ticket {
        address owner;
        uint256 id;
    }

    struct Lottery {
        uint256 id;
        uint256 prize;
        uint256 deadline;
        address winner;
        mapping (address => Ticket) ticketOwners;
    }

    mapping (uint256 => Lottery) lotteryIds;

    function createLottery() external {

    }

    function getATicket() public {

    }

    function chooseWinner() internal {

    }

    function claimWinnings() external {

    }









}