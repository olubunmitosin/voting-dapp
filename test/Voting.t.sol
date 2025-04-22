// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting voting;
    address proposalAddress = address(0x456);
    address voter1 = address(0x789);
    address voter2 = address(0xabc);

    event Voted(address indexed voter, uint8 vote);
    event AlreadyVoted(address indexed voter);
    event InvalidVoteOption(address indexed voter, uint8 invalidVote);
    event ZeroAddressVoter(address zeroAddress);

    function setUp() public {
        voting = new Voting(proposalAddress);
    }

    function testConstructor() public view {
        assertEq(
            voting.proposal(),
            proposalAddress,
            "Proposal address should be correct"
        );
    }

    function testCastVote() public {
        vm.prank(voter1);
        voting.castVote(1); // Vote Yes

        assertTrue(voting.hasVoted(voter1), "Voter 1 should have voted");
        assertEq(voting.voteCounts(1), 1, "Yes vote count should be 1");
        assertEq(voting.totalVotes(), 1, "Total votes should be 1");
        assertEq(voting.getVoters().length, 1, "Number of voters should be 1");
        assertEq(
            voting.getVoters()[0],
            voter1,
            "Voter 1 should be in the voters list"
        );

        emit Voted(voter1, 1);
    }

    function testCastMultipleVotes() public {
        vm.prank(voter1);
        voting.castVote(1);

        vm.prank(voter2);
        voting.castVote(0); // Vote No

        assertTrue(voting.hasVoted(voter1), "Voter 1 should have voted");
        assertTrue(voting.hasVoted(voter2), "Voter 2 should have voted");
        assertEq(voting.voteCounts(1), 1, "Yes vote count should be 1");
        assertEq(voting.voteCounts(0), 1, "No vote count should be 1");
        assertEq(voting.totalVotes(), 2, "Total votes should be 2");
        assertEq(voting.getVoters().length, 2, "Number of voters should be 2");
        assertEq(
            voting.getVoters()[0],
            voter1,
            "Voter 1 should be in the voters list"
        );
        assertEq(
            voting.getVoters()[1],
            voter2,
            "Voter 2 should be in the voters list"
        );

        emit Voted(voter1, 1);
        emit Voted(voter2, 0);
    }

    function testCastVoteTwice() public {
        vm.prank(voter1);
        voting.castVote(1);

        vm.expectRevert("Already voted");
        emit AlreadyVoted(voter1);
        vm.prank(voter1);
        voting.castVote(0);
    }

    function testCastInvalidVote() public {
        vm.prank(voter1);
        vm.expectRevert("Invalid vote option");
        emit InvalidVoteOption(voter1, 2);
        voting.castVote(2);

        vm.expectRevert("Invalid vote option");
        emit InvalidVoteOption(voter1, 255);
        voting.castVote(255);
    }

    function testCastVoteFromZeroAddress() public {
        vm.expectRevert("Voter address cannot be zero");
        vm.prank(address(0)); // Set the sender to the zero address
        voting.castVote(1);
        emit ZeroAddressVoter(address(0)); // Emit the event after the call (for verification if needed)
    }

    function testGetVoteCount() public {
        vm.prank(voter1);
        voting.castVote(1);
        vm.prank(voter2);
        voting.castVote(0);

        assertEq(voting.getVoteCount(0), 1, "No votes should be 1");
        assertEq(voting.getVoteCount(1), 1, "Yes votes should be 1");
        assertEq(
            voting.getVoteCount(2),
            0,
            "Invalid option should have 0 votes"
        );
    }

    function testGetVoters() public {
        vm.prank(voter1);
        voting.castVote(1);
        vm.prank(voter2);
        voting.castVote(0);

        address[] memory votersList = voting.getVoters();
        assertEq(votersList.length, 2, "Should have 2 voters");
        assertEq(votersList[0], voter1, "First voter should be voter1");
        assertEq(votersList[1], voter2, "Second voter should be voter2");
    }
}
