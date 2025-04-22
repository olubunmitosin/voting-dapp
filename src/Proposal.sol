// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Proposal {
    // proposal address
    address public proposer;
    // proposal description
    string public description;
    // start time
    uint256 public startTime;
    // end time
    uint256 public endTime;
    // execution flag
    bool public executed;

    // proposal created event
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    // proposal executed event
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalExecutionAttemptedAfterExecution(uint256 indexed proposalId);

    // Proposal constructor
    constructor(
        address _proposer,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) {
        proposer = _proposer;
        description = _description;
        startTime = _startTime;
        endTime = _endTime;
        executed = false;

        emit ProposalCreated(
            uint256(address(this).codehash),
            _proposer,
            _description,
            _startTime,
            _endTime
        );
    }

    // Mark proposal as executed
    function markAsExecuted() external {
        if (executed) {
            emit ProposalExecutionAttemptedAfterExecution(
                uint256(address(this).codehash)
            );
            revert("Proposal already executed");
        }
        executed = true;
        emit ProposalExecuted(uint256(address(this).codehash));
    }
}
