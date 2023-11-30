// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LotteryContract {
    struct Ticket {
        address owner;
        uint256 ticketId;
    }

    struct Lottery {
        uint256 id;
        uint256 prize;
        uint256 deadline;
        uint256 endBlock;
        address winner;
        mapping (address => Ticket) ticketOwners;
        address [] ticketOwnersArray;
        address owner;
    }

    mapping (uint256 => Lottery) public lotteryIds;
    uint256 public lotteryId;
    mapping (uint256 => uint256) public lotteryBalances;

    event LotteryCreated(uint256 lotteryId, uint256 prize, uint256 deadline, address owner);
    event TicketPurchased(uint256 lotteryId, address owner, uint256 ticketId);
    event WinnerChosen(uint256 lotteryId, address winner);
    event WinningsClaimed(uint256 lotteryId, address winner, uint256 prize);

    function createLottery(uint256 _prize, uint256 _deadline) external {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        Lottery storage lottery = lotteryIds[lotteryId];
        lottery.id = lotteryId;
        lottery.prize = _prize;
        lottery.deadline = _deadline + 24 hours; // Set deadline 24 hours after creation
        lottery.endBlock = block.number + 5760; // Approx 24 hours later in blocks (15 sec per block)
        lottery.owner = msg.sender;
        lotteryId++;
        emit LotteryCreated(lottery.id, lottery.prize, lottery.deadline, lottery.owner);
    }

    function getATicket(uint256 _lotteryId) public payable {
        require(lotteryIds[_lotteryId].deadline > block.timestamp, "Lottery has ended");
        require(msg.value == 1 ether, "Ticket costs 1 ether");
        require(lotteryBalances[_lotteryId] + msg.value <= lotteryIds[_lotteryId].prize, "Lottery is full");

        Lottery storage lottery = lotteryIds[_lotteryId];
        Ticket memory ticket = Ticket(msg.sender, lottery.ticketOwnersArray.length);
        lottery.ticketOwners[msg.sender] = ticket;
        lottery.ticketOwnersArray.push(msg.sender);
        lotteryBalances[_lotteryId] += msg.value;
        emit TicketPurchased(_lotteryId, msg.sender, lottery.ticketOwnersArray.length);
    }

    function chooseWinner(uint256 _lotteryId) external {
        Lottery storage lottery = lotteryIds[_lotteryId];
        require(block.number > lottery.endBlock, "Lottery is still active"); // Check against endBlock
        require(lottery.winner == address(0), "Winner has already been chosen");
        require(lottery.ticketOwnersArray.length > 0, "No tickets were sold");

        uint256 blockNumber = block.number - 1; // Ideally, use a block number that's known to be valid
        uint256 randomHash = uint(blockhash(blockNumber));
        require(randomHash != 0, "Blockhash not available");

        uint256 randomIndex = randomHash % lottery.ticketOwnersArray.length;
        address winner = lottery.ticketOwnersArray[randomIndex];
        lottery.winner = winner;
        emit WinnerChosen(_lotteryId, winner);
    }

    function claimWinnings(uint256 _lotteryId) external {
        Lottery storage lottery = lotteryIds[_lotteryId];
        require(lottery.winner == msg.sender, "You are not the winner");
        require(block.number <= lottery.endBlock + 256, "Claim period has expired"); // Corrected logic for claim period

        payable(msg.sender).transfer(lottery.prize);
        emit WinningsClaimed(_lotteryId, msg.sender, lottery.prize);
        lottery.prize = 0; // Reset prize to prevent double claiming
    }
}
