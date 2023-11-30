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
    mapping (uint256 => uint256) public lotteryBalances;

    function createLottery(uint256 _prize, uint256 _deadline) external {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        Lottery storage lottery = lotteryIds[lotteryId];
        lottery.id = lotteryId;
        lottery.prize = _prize;
        lottery.deadline = _deadline;
        lottery.owner = msg.sender;
        lotteryId++;
    }

    function getATicket(uint256 _lotteryId) public payable {
        require(lotteryIds[_lotteryId].deadline > block.timestamp, "Lottery has ended");
        require(msg.value == 1 ether, "Ticket costs 1 ether");
        address(this).transfer(msg.value);
        Lottery storage lottery = lotteryIds[_lotteryId];
        Ticket memory ticket = Ticket(msg.sender, lottery.ticketOwnersArray.length);
        lottery.ticketOwners[msg.sender] = ticket;
        lotteryBalances[_lotteryId] += msg.value;
    }

    function chooseWinner(uint256 _lotteryId) external {
        Lottery storage lottery = lotteryIds[_lotteryId];

        // Ensure the lottery's deadline has passed and there's no winner yet
        require(block.timestamp > lottery.deadline, "Lottery is still active");
        require(lottery.winner == address(0), "Winner has already been chosen");
        require(lottery.ticketOwnersArray.length > 0, "No tickets were sold");

        // Using the blockhash of a future block for randomness
        // Note: This should ideally be a block after the deadline
        uint256 blockNumber = block.number - 1;
        uint256 randomHash = uint(blockhash(blockNumber));

        // Ensure the blockhash is not zero (only valid for the last 256 blocks)
        require(randomHash != 0, "Blockhash not available");

        // Selecting a random index from the ticketOwnersArray
        uint256 randomIndex = randomHash % lottery.ticketOwnersArray.length;
        address winner = lottery.ticketOwnersArray[randomIndex];

        // Setting the winner
        lottery.winner = winner;

        // Additional logic for handling the prize distribution can be added here
    }


    function claimWinnings(uint256 _lotteryId) external {
        require(lotteryIds[_lotteryId].winner == msg.sender, "You are not the winner");
        require(block.number <= 256, "You are too late");
        payable(msg.sender).transfer(lotteryIds[_lotteryId].prize);
    }









}