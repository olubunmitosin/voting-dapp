// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/DAO.sol";

contract DeployDAO is Script {
    DAO public dao;

    function run() public {
        // Get the deployer private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get the deployer address from the private key
        address deployer = vm.addr(deployerPrivateKey);

        // Broadcast the deployment transaction with the deployer as tx.origin
        vm.startBroadcast(deployer);
        dao = new DAO();
        console.log("DAO deployed to:", address(dao));

        // Optional: Add initial members and grant voting rights
        // Replace these addresses with your desired initial members
        address member1 = address(0x002);
        address member2 = address(0x003);
        address voter1 = address(0x004);

        // All subsequent calls within the broadcast will originate from the deployer
        dao.addMember(member1);
        console.log("Member added:", member1);
        dao.addMember(member2);
        console.log("Member added:", member2);
        dao.addMember(voter1);
        console.log("Member added:", voter1);
        vm.stopBroadcast();
    }
}
