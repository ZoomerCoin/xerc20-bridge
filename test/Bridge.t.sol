// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Bridge} from "../src/Bridge.sol";

contract BridgeTest is Test {
    Bridge bridge;
    address connextBridge = address(1);

    function setUp() public {
        bridge = new Bridge();
        Bridge.BridgeType[] memory bridgeTypes = new Bridge.BridgeType[](1);
        bridgeTypes[0] = Bridge.BridgeType.Connext;
        address[] memory bridges = new address[](1);
        bridges[0] = connextBridge;
        bridge.initialize(5, bridgeTypes, bridges);
    }

    function test_setFee_failsIfOutOfBounds() public {
        vm.expectRevert(abi.encodeWithSelector(Bridge.FeeOutOfBounds.selector, 101));
        bridge.setFee(101);
    }

    function test_setFee_works() public {
        bridge.setFee(10);
        uint32 fee = bridge.fee();
        assertEq(fee, 10);
    }

    function test_setBridge_works() public {
        address newBridge = address(2);
        bridge.setBridge(Bridge.BridgeType.Connext, newBridge);
        address bridgeAddress = bridge.bridges(Bridge.BridgeType.Connext);
        assertEq(bridgeAddress, newBridge);
    }

    function test_setDomains_failsIfWrongLengths() public {
        vm.expectRevert(abi.encodeWithSelector(Bridge.LengthsMustMatch.selector, 1, 2));
        bridge.setDomains(new uint32[](1), new uint32[](2));
    }
}
