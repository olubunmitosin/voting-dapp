// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Voting {
    // proposal address
    address public proposal;
    // Mapping to track if an address has voted
    mapping(address => bool) public hasVoted;
    // mapping of vote counts for each option
    // 0: option 1, 1: option 2, 2: option 3
    mapping(uint8 => uint256) public voteCounts;
    // total votes
    uint256 public totalVotes;
    // collection of voters
    address[] public voters;

    // event to emit when a vote is cast
    event Voted(address indexed voter, uint8 vote);
    // Event emitted when a voter tries to vote again
    event AlreadyVoted(address indexed voter);
    // Event emitted when an invalid vote option is provided
    event InvalidVoteOption(address indexed voter, uint8 invalidVote);
    // Event emitted when a zero address attempts to vote
    event ZeroAddressVoter(address zeroAddress);

    // Voting constructor
    constructor(address _proposal) {
        proposal = _proposal;
    }

    // Cast vote
    function castVote(uint8 _vote) external {
        // Input validation and security checks
        if (msg.sender == address(0)) {
            emit ZeroAddressVoter(address(0));
            revert("Voter address cannot be zero");
        }
        if (hasVoted[msg.sender]) {
            emit AlreadyVoted(msg.sender);
            revert("Already voted");
        }
        if (_vote != 0 && _vote != 1) {
            emit InvalidVoteOption(msg.sender, _vote);
            revert("Invalid vote option"); // Assuming 0 for No, 1 for Yes
        }

        // Record the vote
        hasVoted[msg.sender] = true;
        voteCounts[_vote]++;
        totalVotes++;
        voters.push(msg.sender);
        emit Voted(msg.sender, _vote);
    }

    // Get vote counts for each option
    function getVoteCount(uint8 _voteOption) external view returns (uint256) {
        return voteCounts[_voteOption];
    }

    // Get total voters
    function getVoters() external view returns (address[] memory) {
        return voters;
    }
}
