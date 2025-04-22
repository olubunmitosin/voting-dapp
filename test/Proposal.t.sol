// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Proposal.sol";

contract ProposalTest is Test {
    Proposal proposal;
    address proposer = address(0x123);
    string description = "Test Proposal";
    uint256 startTime;
    uint256 endTime;

    event ProposalCreated(
        uint256 proposalId,
        address proposal,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    event ProposalExecuted(uint256 proposalId);

    event ProposalExecutionAttemptedAfterExecution(uint256 proposalId);

    function setUp() public {
        startTime = block.timestamp;
        endTime = startTime + 7 days;
        proposal = new Proposal(proposer, description, startTime, endTime);
    }

    function testProposalCreation() public {
        assertEq(proposal.proposer(), proposer, "Proposer should be correct");
        assertEq(
            proposal.description(),
            description,
            "Description should be correct"
        );
        assertEq(
            proposal.startTime(),
            startTime,
            "Start time should be correct"
        );
        assertEq(proposal.endTime(), endTime, "End time should be correct");
        assertFalse(proposal.executed(), "Should not be executed initially");

        emit ProposalCreated(
            uint256(address(proposal).codehash),
            proposer,
            description,
            startTime,
            endTime
        );
    }

    function testMarkAsExecuted() public {
        assertFalse(proposal.executed(), "Should not be executed initially");
        proposal.markAsExecuted();
        assertTrue(
            proposal.executed(),
            "Should be executed after calling markAsExecuted"
        );

        emit ProposalExecuted(uint256(address(proposal).codehash));
    }

    function testMarkAsExecutedTwice() public {
        proposal.markAsExecuted();
        assertTrue(
            proposal.executed(),
            "Should be executed after the first call"
        );

        vm.expectRevert("Proposal already executed");
        emit ProposalExecutionAttemptedAfterExecution(
            uint256(address(proposal).codehash)
        );
        proposal.markAsExecuted();
    }
}
