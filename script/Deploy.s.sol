// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/DAO.sol";

contract DeployDAO is Script {
    DAO public dao;

    function run() public {
        // Broadcast the deployment transaction
        vm.startBroadcast();
        dao = new DAO();
        console.log("DAO deployed to:", address(dao));

        // Optional: Add initial members and grant voting rights
        // Replace these addresses with your desired initial members
        address member1 = address(0x002);
        address member2 = address(0x003);
        address voter1 = address(0x004);

        vm.prank(msg.sender);
        dao.addMember(member1);
        console.log("Member added:", member1);
        dao.addMember(member2);
        console.log("Member added:", member2);
        dao.addMember(voter1);
        console.log("Member added:", voter1);

        dao.grantVotingRights(member1);
        console.log("Voting rights granted to:", member1);
        dao.grantVotingRights(voter1);
        console.log("Voting rights granted to:", voter1);

        vm.stopBroadcast();
    }
}
