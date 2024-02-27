// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    uint256 SEND_VALUE = 0.1 ether;

    function createSubscriptionUsingConfig() public returns (uint64) {
        
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , ,) = helperConfig.activeNetworkConfig();
        
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) {
      console.log("Creating subscription with vrfCoordinator: %s on chainId: %s", vrfCoordinator, block.chainid);
      vm.startBroadcast();

      uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
      console.log("Subscription created with id: %s", subId);
      vm.stopBroadcast();

      return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId , , address link) = helperConfig.activeNetworkConfig();
        
        fundSubscription(vrfCoordinator, subId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link ) public {
      console.log("Funding subscription with vrfCoordinator: %s on chainId: %s with subId: %s", vrfCoordinator, block.chainid, subId);
      
    
      if (block.chainid == 31337) {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
        vm.stopBroadcast();
      } else {
        vm.startBroadcast();
        LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
        vm.stopBroadcast();
      }

      console.log("Subscription funded");
      
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffle) public {
        
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId , , ) = helperConfig.activeNetworkConfig();
        
        addConsumer(vrfCoordinator, subId, raffle);
    }

    function addConsumer(address vrfCoordinator, uint64 subId, address raffle) public {
      console.log("Adding consumer with vrfCoordinator: ", vrfCoordinator);
      console.log("on chain id: ", block.chainid);
      console.log("Sub id: ", subId);
      console.log("Raffle contract: ", raffle);
       
      vm.startBroadcast();
      VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
      vm.stopBroadcast();
      console.log("Consumer added");
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
