// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/DAO.sol";
import "../src/Proposal.sol";
import "../src/Voting.sol";

contract DAOTest is Test {
    DAO dao;
    address owner = address(0x001);
    address member1 = address(0x002);
    address member2 = address(0x003);
    address voter1 = address(0x004);
    address voter2 = address(0x005);
    string proposalDescription = "Test DAO Proposal";
    uint256 proposalDuration = 7 days;
    uint256 proposalId;
    address proposalAddress;
    address votingAddress;
    bytes proposalPayload =
        abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(0x006),
            100
        );

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event VotingRightsGranted(address indexed member);
    event VotingRightsRevoked(address indexed member);
    event ProposalCreated(
        uint256 indexed proposalId,
        address proposalAddress,
        address proposer,
        uint256 startTime,
        uint256 endTime
    );
    event ProposalVotingStarted(
        uint256 indexed proposalId,
        address votingAddress
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateUpdated(
        uint256 indexed proposalId,
        DAO.ProposalState newState
    );
    event ExecutionFailed(
        uint256 indexed proposalId,
        string reason,
        bytes returnData
    );
    event QuorumNotReached(
        uint256 indexed proposalId,
        uint256 totalVotes,
        uint256 requiredQuorum
    );
    event PassingThresholdNotMet(
        uint256 indexed proposalId,
        uint256 yesVotes,
        uint256 requiredThreshold
    );
    event ProposalAlreadyExecuted(uint256 indexed proposalId);
    event VotingNotEnded(
        uint256 indexed proposalId,
        uint256 endTime,
        uint256 currentTime
    );
    event ProposalNotFound(uint256 indexed proposalId);
    event VotingNotStarted(uint256 indexed proposalId);
    event NotAMember(address indexed sender);
    event NotEligibleToVote(address indexed sender);
    event Voted(address indexed voter, uint8 vote); // Need to declare this here as well since we interact with the Voting contract

    function setUp() public {
        vm.prank(owner);
        dao = new DAO();
        vm.prank(owner);
        dao.addMember(member1);
        vm.prank(owner);
        dao.addMember(member2);
        vm.prank(owner);
        dao.grantVotingRights(member1);
        vm.prank(owner);
        dao.grantVotingRights(voter1); // voter1 is a member with voting rights
    }

    function testAddMember() public {
        address newMember = address(0x007);
        vm.prank(owner);
        dao.addMember(newMember);
        assertTrue(dao.isMember(newMember), "New member should be added");
        assertEq(dao.getMemberCount(), 3, "Member count should increase");
        assertEq(dao.getMembers().length, 3, "Members array should update");
        assertEq(
            dao.getMembers()[2],
            newMember,
            "New member should be in the members array"
        );
        emit MemberAdded(newMember);
    }

    function testRemoveMember() public {
        vm.prank(owner);
        dao.removeMember(member1);
        assertFalse(dao.isMember(member1), "Member should be removed");
        assertFalse(dao.canVote(member1), "Voting rights should be revoked");
        assertEq(dao.getMemberCount(), 1, "Member count should decrease");
        assertEq(dao.getMembers().length, 1, "Members array should update");
        assertEq(dao.getVoterCount(), 1, "Voter count should decrease");
        emit MemberRemoved(member1);
        emit VotingRightsRevoked(member1);
    }

    function testGrantVotingRights() public {
        vm.prank(owner);
        dao.grantVotingRights(member2);
        assertTrue(dao.canVote(member2), "Member should have voting rights");
        assertEq(dao.getVoterCount(), 2, "Voter count should increase");
        uint256 voterCount = dao.getVoterCount();
        address[] memory currentVoters = new address[](voterCount);
        for (uint256 i = 0; i < voterCount; i++) {
            currentVoters[i] = dao.voters(i);
        }
        assertEq(currentVoters.length, 2, "Voters array should update");
        assertEq(
            currentVoters[1],
            member2,
            "Member2 should be in voters array"
        );
        emit VotingRightsGranted(member2);
    }

    function testRevokeVotingRights() public {
        vm.prank(owner);
        dao.revokeVotingRights(member1);
        assertFalse(dao.canVote(member1), "Voting rights should be revoked");
        assertEq(dao.getVoterCount(), 1, "Voter count should decrease");
        // Note: Removing from array can be complex to test index directly without iterating
        emit VotingRightsRevoked(member1);
    }

    function testCreateExecutableProposal() public {
        vm.prank(member1);
        uint256 newProposalId = dao.createExecutableProposal(
            proposalDescription,
            proposalDuration,
            address(0x006),
            proposalPayload
        );
        proposalAddress = dao.proposals(newProposalId);
        assertNotEq(
            proposalAddress,
            address(0),
            "Proposal contract should be deployed"
        );
        assertEq(dao.proposalCount(), 1, "Proposal count should be 1");
        assertEq(
            uint256(dao.proposalStates(newProposalId)),
            uint256(DAO.ProposalState.Pending),
            "Proposal state should be Pending"
        );
        assertEq(
            dao.proposalPayloads(newProposalId),
            proposalPayload,
            "Proposal payload should be stored"
        );
        emit ProposalCreated(
            newProposalId,
            proposalAddress,
            member1,
            block.timestamp,
            block.timestamp + proposalDuration
        );
        emit ProposalStateUpdated(newProposalId, DAO.ProposalState.Pending);
    }

    function testStartProposalVoting() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            proposalDuration,
            address(0x006),
            proposalPayload
        );
        vm.prank(member1);
        votingAddress = dao.startProposalVoting(proposalId);
        assertNotEq(
            votingAddress,
            address(0),
            "Voting contract should be deployed"
        );
        assertEq(
            dao.votingContracts(proposalId),
            votingAddress,
            "Voting contract address should be stored"
        );
        assertEq(
            uint256(dao.proposalStates(proposalId)),
            uint256(DAO.ProposalState.Active),
            "Proposal state should be Active"
        );
        emit ProposalVotingStarted(proposalId, votingAddress);
        emit ProposalStateUpdated(proposalId, DAO.ProposalState.Active);
    }

    function testCastVoteOnProposal() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            proposalDuration,
            address(0x006),
            proposalPayload
        );
        vm.prank(member1);
        dao.startProposalVoting(proposalId);
        vm.prank(member1);
        dao.castVote(proposalId, 1); // Vote Yes

        Voting votingContract = Voting(dao.votingContracts(proposalId));
        assertTrue(
            votingContract.hasVoted(member1),
            "Member 1 should have voted"
        );
        assertEq(votingContract.voteCounts(1), 1, "Yes votes should be 1");
        emit Voted(member1, 1);
    }

    function testExecuteProposalSuccess() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            1,
            address(this),
            abi.encodeWithSignature("")
        ); // Short duration
        vm.prank(member1);
        dao.startProposalVoting(proposalId);
        vm.prank(member1);
        dao.castVote(proposalId, 1); // Vote Yes (only voter)

        // Fast forward time so voting ends
        vm.warp(block.timestamp + 2);

        vm.prank(member1);
        dao.executeProposal(proposalId);

        Proposal proposalContract = Proposal(dao.proposals(proposalId));
        assertTrue(proposalContract.executed(), "Proposal should be executed");
        assertEq(
            uint256(dao.proposalStates(proposalId)),
            uint256(DAO.ProposalState.Executed),
            "Proposal state should be Executed"
        );
        emit ProposalExecuted(proposalId);
        emit ProposalStateUpdated(proposalId, DAO.ProposalState.Executed);
    }

    function testExecuteProposalQuorumNotReached() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            1,
            address(this),
            abi.encodeWithSignature("")
        );
        vm.prank(member1);
        dao.startProposalVoting(proposalId);

        // Only one voter (member1), quorum is 50% of voters (which is 1), but only 1 vote cast.
        vm.warp(block.timestamp + 2);

        vm.expectRevert("Quorum not reached");
        emit QuorumNotReached(proposalId, 0, 1); // No votes cast
        vm.prank(member1);
        dao.executeProposal(proposalId);
        assertEq(
            uint256(dao.proposalStates(proposalId)),
            uint256(DAO.ProposalState.Defeated),
            "Proposal state should be Defeated"
        );
        emit ProposalStateUpdated(proposalId, DAO.ProposalState.Defeated);
    }

    function testExecuteProposalNotPassed() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            1,
            address(this),
            abi.encodeWithSignature("")
        );
        vm.prank(member1);
        dao.startProposalVoting(proposalId);
        vm.prank(voter1); // Only voter with rights
        dao.castVote(proposalId, 0); // Vote No

        vm.warp(block.timestamp + 2);

        vm.expectRevert("Proposal not passed");
        emit PassingThresholdNotMet(proposalId, 0, 1); // 0 Yes votes, threshold is 60% of 1 = 0
        vm.prank(member1);
        dao.executeProposal(proposalId);
        assertEq(
            uint256(dao.proposalStates(proposalId)),
            uint256(DAO.ProposalState.Defeated),
            "Proposal state should be Defeated"
        );
        emit ProposalStateUpdated(proposalId, DAO.ProposalState.Defeated);
    }

    function testExecuteProposalVotingNotEnded() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            7 days,
            address(this),
            abi.encodeWithSignature("")
        );
        vm.prank(member1);
        dao.startProposalVoting(proposalId);
        vm.prank(member1);
        dao.castVote(proposalId, 1);

        vm.expectRevert("Voting has not ended");
        emit VotingNotEnded(
            proposalId,
            block.timestamp + 7 days,
            block.timestamp
        );
        vm.prank(member1);
        dao.executeProposal(proposalId);
    }

    function testExecuteProposalAlreadyExecuted() public {
        vm.prank(member1);
        proposalId = dao.createExecutableProposal(
            proposalDescription,
            1,
            address(this),
            abi.encodeWithSignature("")
        );
        vm.prank(member1);
        dao.startProposalVoting(proposalId);
        vm.prank(member1);
        dao.castVote(proposalId, 1);
        vm.warp(block.timestamp + 2);
        vm.prank(member1);
        dao.executeProposal(proposalId);

        vm.expectRevert("Proposal already executed");
        emit ProposalAlreadyExecuted(proposalId);
        vm.prank(member1);
        dao.executeProposal(proposalId);
    }
}
