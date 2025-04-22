// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Proposal.sol";
import "./Voting.sol";

contract DAO {
    // Owner of the DAO
    // The owner is the address that deployed the contract
    address public owner;
    // mapping to check if a member is part of the DAO
    mapping(address => bool) public isMember;
    // mapping to check if a member can vote
    mapping(address => bool) public canVote;
    // Mapping proposal ID to the Proposal contract address
    mapping(uint256 => address) public proposals;
    // holder for proposal count
    uint256 public proposalCount;
    // mapping to hold voting contracts
    mapping(uint256 => address) public votingContracts;
    // mapping to hold proposal states
    mapping(uint256 => ProposalState) public proposalStates;
    // Store encoded function calls and arguments
    mapping(uint256 => bytes) public proposalPayloads;

    address[] public members;
    address[] public voters;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Passed,
        Executed
    }

    /**
     * Events to emit at different stages of the DAO lifecycle
     */
    event MemberAdded(address indexed member); // when a member is added to the DAO
    event MemberRemoved(address indexed member); // when a member is removed from the DAO
    event VotingRightsGranted(address indexed member); // when voting rights are granted to a member
    event VotingRightsRevoked(address indexed member); // when voting rights are revoked from a member
    event ProposalCreated(
        uint256 indexed proposalId,
        address proposalAddress,
        address proposal
    ); // when a proposal is created
    event ProposalVotingStarted(
        uint256 indexed proposalId,
        address votingAddress
    ); // when voting starts for a proposal
    event ProposalExecuted(uint256 indexed proposalId); // when a proposal is executed
    event ProposalStateUpdated(
        uint256 indexed proposalId,
        ProposalState newState
    ); // when a proposal state is updated
    event ExecutionFailed(
        uint256 indexed proposalId,
        string reason,
        bytes returnData
    ); // when execution fails
    event QuorumNotReached(
        uint256 indexed proposalId,
        uint256 totalVotes,
        uint256 requiredQuorum
    ); // when quorum is not reached
    event PassingThresholdNotMet(
        uint256 indexed proposalId,
        uint256 yesVotes,
        uint256 requiredThreshold
    ); // when passing threshold is not met
    event ProposalAlreadyExecuted(uint256 indexed proposalId); // when a proposal is already executed
    event VotingNotEnded(
        uint256 indexed proposalId,
        uint256 endTime,
        uint256 currentTime
    ); // when voting has not ended
    event ProposalNotFound(uint256 indexed proposalId); // when a proposal is not found
    event VotingNotStarted(uint256 indexed proposalId); // when voting has not started for a proposal
    event NotAMember(address indexed sender); // when a non-member tries to access member-only functions
    event NotEligibleToVote(address indexed sender); // when a non-voter tries to access voter-only functions

    modifier onlyMember() {
        if (!isMember[msg.sender]) {
            emit NotAMember(msg.sender);
            revert("Not a member");
        }
        _;
    }

    modifier onlyVoter() {
        if (!canVote[msg.sender]) {
            emit NotEligibleToVote(msg.sender);
            revert("Not eligible to vote");
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Handle adding members to the DAO
    // This function can only be called by the owner
    function addMember(address _member) external {
        if (isMember[_member]) revert("Already a member");
        isMember[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    // Remove member from the DAO
    function removeMember(address _member) external {
        if (!isMember[_member]) revert("Not a member");
        isMember[_member] = false;
        // More gas-efficient way to remove from array (order not preserved)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        if (canVote[_member]) {
            canVote[_member] = false;
            for (uint256 i = 0; i < voters.length; i++) {
                if (voters[i] == _member) {
                    voters[i] = voters[voters.length - 1];
                    voters.pop();
                    break;
                }
            }
        }
        emit MemberRemoved(_member);
    }

    // Grant voting rights to a member
    // This function can only be called by the owner of the contract
    function grantVotingRights(address _member) external onlyMember {
        if (!isMember[_member]) revert("Not a member");
        if (canVote[_member]) revert("Already has voting rights");
        canVote[_member] = true;
        voters.push(_member);
        emit VotingRightsGranted(_member);
    }

    // Revoke voting rights from a member
    // This function can only be called by the owner of the contract
    function revokeVotingRights(address _member) external onlyMember {
        if (!canVote[_member]) revert("Does not have voting rights");
        canVote[_member] = false;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _member) {
                voters[i] = voters[voters.length - 1];
                voters.pop();
                break;
            }
        }
        emit VotingRightsRevoked(_member);
    }

    // Create a new proposal
    // This function can only be called by a member of the DAO
    function createExecutableProposal(
        string memory _description,
        uint256 _durationInSeconds,
        address /* _target */,
        bytes memory _payload
    ) external onlyMember returns (uint256) {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _durationInSeconds;
        Proposal newProposal = new Proposal(
            msg.sender,
            _description,
            startTime,
            endTime
        );
        proposalCount++;
        proposals[proposalCount] = address(newProposal);
        proposalStates[proposalCount] = ProposalState.Pending;
        proposalPayloads[proposalCount] = _payload;
        emit ProposalCreated(proposalCount, address(newProposal), msg.sender);
        emit ProposalStateUpdated(proposalCount, ProposalState.Pending);
        return proposalCount;
    }

    // Start voting for a proposal
    // This function can only be called by a member of the DAO
    function startProposalVoting(
        uint256 _proposalId
    ) external onlyMember returns (address) {
        if (proposals[_proposalId] == address(0)) {
            emit ProposalNotFound(_proposalId);
            revert("Proposal not found");
        }
        if (proposalStates[_proposalId] != ProposalState.Pending) {
            revert("Proposal voting can only start in Pending state");
        }
        Proposal proposalContract = Proposal(proposals[_proposalId]);
        Voting newVoting = new Voting(address(proposalContract));
        votingContracts[_proposalId] = address(newVoting);
        proposalStates[_proposalId] = ProposalState.Active;
        emit ProposalVotingStarted(_proposalId, address(newVoting));
        emit ProposalStateUpdated(_proposalId, ProposalState.Active);
        return address(newVoting);
    }

    // Cast voting
    function castVote(
        uint256 _proposalId,
        uint8 _vote
    ) external onlyMember onlyVoter {
        if (proposals[_proposalId] == address(0)) {
            emit ProposalNotFound(_proposalId);
            revert("Proposal not found");
        }
        if (votingContracts[_proposalId] == address(0)) {
            emit VotingNotStarted(_proposalId);
            revert("Voting not started for this proposal");
        }
        Voting votingContract = Voting(votingContracts[_proposalId]);
        votingContract.castVote(_vote);
    }

    // Execute the proposal
    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal proposalContract = Proposal(proposals[_proposalId]);

        if (proposalStates[_proposalId] != ProposalState.Active) {
            revert("Proposal must be in Active state to execute");
        }
        if (proposals[_proposalId] == address(0)) {
            emit ProposalNotFound(_proposalId);
            revert("Proposal not found");
        }
        if (votingContracts[_proposalId] == address(0)) {
            emit VotingNotStarted(_proposalId);
            revert("Voting not started for this proposal");
        }

        if (block.timestamp <= proposalContract.endTime()) {
            emit VotingNotEnded(
                _proposalId,
                proposalContract.endTime(),
                block.timestamp
            );
            revert("Voting has not ended");
        }
        if (proposalContract.executed()) {
            revert("Proposal already executed");
        }

        Voting votingContract = Voting(votingContracts[_proposalId]);
        uint256 yesVotes = votingContract.getVoteCount(1);
        uint256 totalVotes = votingContract.totalVotes();
        uint256 currentVoterCount = voters.length;

        uint256 quorum = (currentVoterCount * 50) / 100;
        uint256 passingThreshold = (totalVotes * 60) / 100;

        if (totalVotes < quorum) {
            proposalStates[_proposalId] = ProposalState.Defeated;
            emit ProposalStateUpdated(_proposalId, ProposalState.Defeated);
            emit QuorumNotReached(_proposalId, totalVotes, quorum);
            revert("Quorum not reached");
        }

        if (yesVotes <= passingThreshold) {
            proposalStates[_proposalId] = ProposalState.Defeated;
            emit ProposalStateUpdated(_proposalId, ProposalState.Defeated);
            emit PassingThresholdNotMet(
                _proposalId,
                yesVotes,
                passingThreshold
            );
            revert("Proposal not passed");
        }

        // Execute the proposal
        (bool success, bytes memory returnData) = address(this).call{value: 0}(
            "" // Explicitly empty data
        );

        if (success) {
            proposalContract.markAsExecuted();
            proposalStates[_proposalId] = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
            emit ProposalStateUpdated(_proposalId, ProposalState.Executed);
            // Process returnData if needed
        } else {
            proposalStates[_proposalId] = ProposalState.Defeated;
            emit ProposalStateUpdated(_proposalId, ProposalState.Defeated);
            emit ExecutionFailed(_proposalId, string(returnData), returnData);
            revert(string(returnData));
        }
    }

    // Get the voter count
    function getVoterCount() public view returns (uint256) {
        return voters.length;
    }

    // Get members of the DAO
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // Get members count
    function getMemberCount() public view returns (uint256) {
        return members.length;
    }

    receive() external payable {}
}
