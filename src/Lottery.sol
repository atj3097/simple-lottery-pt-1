// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
/*

Simple lottery
Any user can call createLottery and a lottery will be created with a ticket purchase window
for the next 24 hours. Once the 24 hours is up, there is a 1 hour delay,
then the lottery is over. Generating random numbers safely on Ethereum is tricky,
but for the purpose of this, relying on a future blockhash (which the players cannot predict),
is good enough for this project.
After createLottery is called people can purchaseTicket for a particular lotteryId.
The lottery must consist of a deadline for when purchasing tickets stops,
and time afterwards when the future blockhash determines the winner.
The winner must then claim the winnings within 256 blocks (the maximum lookback of the blockhash function),
otherwise, everyone can get their tickets back.
*/

contract LotteryContract {

    struct Ticket {
        address owner;
        uint256 ticketId;
    }

    struct Lottery {
        uint256 id;
        uint256 prize;
        uint256 deadline;
        address winner;
        mapping (address => Ticket) ticketOwners;
        address [] ticketOwnersArray;
        address owner;
    }

    mapping (uint256 => Lottery) public lotteryIds;
    uint256 public lotteryId;

    function createLottery(uint256 _prize, uint256 _deadline) external {
        lotteryIds[lotteryId] = Lottery(lotteryId, _prize, _deadline, address(0), msg.sender);
        lotteryId++;
    }

    function getATicket(uint256 _lotteryId) public {
        require(lotteryIds[_lotteryId].deadline > block.timestamp, "Lottery has ended");
        Lottery storage lottery = lotteryIds[_lotteryId];
        Ticket ticket = Ticket(msg.sender, lottery.ticketOwnersArray.length);
        lottery.ticketOwners[msg.sender] = ticket;
    }

    function chooseWinner() internal {

    }

    function claimWinnings() external {

    }









}