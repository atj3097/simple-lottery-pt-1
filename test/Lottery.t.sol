// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Lottery.sol";

contract LotteryContractTest is Test {
    LotteryContract lottery;
    address payable[] users;

    function setUp() public {
        // Deploy the LotteryContract
        lottery = new LotteryContract();

        // Create test accounts
        users = new address payable[](3);
        for (uint i = 0; i < 3; i++) {
            users[i] = payable(address(uint160(uint(keccak256(abi.encodePacked(i))))));
        }

        // Set up initial ETH balances for test accounts if necessary
        vm.deal(users[0], 100 ether);
        vm.deal(users[1], 100 ether);
        vm.deal(users[2], 100 ether);
    }

    function testCreateLottery() public {
        uint256 prize = 10 ether;
        uint256 deadline = block.timestamp + 1 days;

        vm.startPrank(users[0]);
        lottery.createLottery(prize, deadline);
        vm.stopPrank();

        // Asserts
        (, uint256 _prize, uint256 _deadline,,,) = lottery.lotteryIds(0);
        assertEq(_prize, prize);
        assertEq(_deadline, deadline);
    }

    function testGetATicket() public {
        uint256 lotteryId = 0;
        uint256 prize = 10 ether;
        uint256 deadline = block.timestamp + 1 days;

        vm.startPrank(users[0]);
        lottery.createLottery(prize, deadline);
        vm.stopPrank();

        uint256 ticketPrice = 1 ether;

        vm.startPrank(users[1]);
        lottery.getATicket{value: ticketPrice}(lotteryId);
        vm.stopPrank();

        // Asserts
        assertEq(lottery.lotteryBalances(lotteryId), ticketPrice);
    }

    function testChooseWinnerAndClaimWinnings() public {
        uint256 lotteryId = 0;
        uint256 prize = 10 ether;
        uint256 deadline = block.timestamp + 1 days;

        vm.startPrank(users[0]);
        lottery.createLottery(prize, deadline);
        vm.stopPrank();

        uint256 ticketPrice = 1 ether;

        for (uint i = 1; i <= 3; i++) {
            vm.startPrank(users[i - 1]);
            lottery.getATicket{value: ticketPrice}(lotteryId);
            vm.stopPrank();
        }

        // Fast-forward time to slightly after the lottery ends
        uint256 warpTime = deadline + 1 minutes;
        vm.warp(warpTime);

        // Log current timestamp for debugging
        emit log_named_uint("Current Timestamp", block.timestamp);
        emit log_named_uint("Warped to Timestamp", warpTime);

        // Assert that we've passed the deadline
        assertTrue(block.timestamp > deadline, "Time warp did not surpass the deadline");

        vm.prank(users[0]); // Lottery creator chooses the winner
        lottery.chooseWinner(lotteryId);

        // Asserts
        (, , , , address winner, ) = lottery.lotteryIds(lotteryId);
        assertTrue(winner != address(0));

        // Claim winnings
        uint256 winnerInitialBalance = winner.balance;
        vm.prank(winner);
        lottery.claimWinnings(lotteryId);

        // Asserts
        assertEq(winner.balance, winnerInitialBalance + prize);
    }


}
