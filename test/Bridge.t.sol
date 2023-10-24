// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Bridge} from "../src/Bridge.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {IConnext} from "connext-interfaces/core/IConnext.sol";

contract TestERC20 is ERC20Upgradeable {
    function initialize() public initializer {
        __ERC20_init("Test", "TEST");
        mint(msg.sender, 100000 ether);
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}

contract TestConnext {
    function xcall(
        uint32 _destination,
        address _to,
        address _asset,
        address _delegate,
        uint256 _amount,
        uint256 _slippage,
        bytes calldata _callData
    ) external payable returns (bytes32) {
        ERC20Upgradeable(_asset).transferFrom(msg.sender, address(this), _amount);
        return bytes32(0);
    }
}

contract BridgeTest is Test {
    Bridge bridge;
    TestConnext connextBridge;
    TestERC20 token;
    address ALICE = address(111);

    function setUp() public {
        connextBridge = new TestConnext();
        bridge = new Bridge();
        Bridge.BridgeType[] memory bridgeTypes = new Bridge.BridgeType[](1);
        bridgeTypes[0] = Bridge.BridgeType.Connext;
        address[] memory bridges = new address[](1);
        bridges[0] = address(connextBridge);
        bridge.initialize(50, bridgeTypes, bridges);

        token = new TestERC20();
        token.initialize();
        token.transfer(ALICE, 100 ether);

        vm.deal(ALICE, 1 ether);
    }

    function test_setFee_failsIfOutOfBounds() public {
        vm.expectRevert(abi.encodeWithSelector(Bridge.FeeOutOfBounds.selector, 10001));
        bridge.setFee(10001);
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

    function test_sendThroughBridge_works() public {
        vm.prank(ALICE);
        token.approve(address(bridge), 100 ether);
        vm.expectCall(
            address(connextBridge),
            0.1 ether,
            abi.encodeCall(
                connextBridge.xcall, (1886350457, ALICE, address(token), ALICE, 99.5 ether, 10000, abi.encode())
            )
        );
        vm.prank(ALICE);
        bridge.sendThroughBridge{value: 0.1 ether}(
            address(token), ALICE, 137, 100 ether, abi.encode(), Bridge.BridgeType.Connext, abi.encode(ALICE, 10000)
        );
    }
}
