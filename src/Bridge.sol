// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {IConnext} from "connext-interfaces/core/IConnext.sol";

contract Bridge is Initializable, Ownable2StepUpgradeable, PausableUpgradeable {
    error InvalidBridgeType();
    error BridgeContractNotSet(BridgeType _bridgeType);
    error DestinationChainNotSupported(uint32 _destinationChainId);
    error FeeOutOfBounds(uint32 _fee);
    error LengthsMustMatch(uint256 _length1, uint256 _length2);

    uint32 public fee;

    enum BridgeType {Connext}

    mapping(BridgeType => address) public bridges;

    mapping(uint32 => uint32) public connextChainIdToDomain;

    function initialize(uint32 _fee, BridgeType[] calldata _bridgeTypes, address[] calldata _bridges)
        public
        initializer
    {
        __Pausable_init();
        __Ownable2Step_init();
        if (_fee < 0 || _fee > 100) revert FeeOutOfBounds(_fee);
        fee = _fee;
        if (_bridgeTypes.length != _bridges.length) revert LengthsMustMatch(_bridgeTypes.length, _bridges.length);
        for (uint256 i = 0; i < _bridgeTypes.length; i++) {
            bridges[_bridgeTypes[i]] = _bridges[i];
        }
    }

    // ADMIN FUNCTIONS
    function setFee(uint32 _fee) external onlyOwner {
        if (_fee < 0 || _fee > 100) revert FeeOutOfBounds(_fee);
        fee = _fee;
    }

    function setBridge(BridgeType _bridgeType, address _bridge) external onlyOwner {
        bridges[_bridgeType] = _bridge;
    }

    function setDomains(uint32[] calldata _connextChainId, uint32[] calldata _domain) external onlyOwner {
        if (_connextChainId.length != _domain.length) revert LengthsMustMatch(_connextChainId.length, _domain.length);
        for (uint256 i = 0; i < _connextChainId.length; i++) {
            connextChainIdToDomain[_connextChainId[i]] = _domain[i];
        }
    }

    function withdraw(address _token, address _recipient, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _recipient, _amount);
    }

    // EXTERNAL FUNCTIONS
    function sendThroughBridge(
        address _token,
        address _recipient,
        uint32 _destinationChainId,
        uint256 _amount,
        bytes calldata _data,
        BridgeType _bridgeType,
        bytes calldata _extraData
    ) external payable whenNotPaused {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_token), msg.sender, address(this), _amount);
        uint256 _amountAfterFee = _amount - ((_amount * fee * 1000) / (100 * 1000));

        if (_bridgeType == BridgeType.Connext) {
            _sendThroughConnext(_token, _recipient, _destinationChainId, _amountAfterFee, _data, _extraData);
        } else {
            revert InvalidBridgeType();
        }
    }

    // INTERNAL FUNCTIONS
    function _sendThroughConnext(
        address _token,
        address _recipient,
        uint32 _destinationChainId,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _extraData
    ) internal {
        address _bridge = bridges[BridgeType.Connext];
        if (_bridge == address(0)) {
            revert BridgeContractNotSet(BridgeType.Connext);
        }
        uint32 _domain = connextChainIdToDomain[_destinationChainId];
        if (_domain == 0) {
            revert DestinationChainNotSupported(_destinationChainId);
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_token), bridges[BridgeType.Connext], _amount);
        (address _delegate, uint256 _slippage) = abi.decode(_extraData, (address, uint256));
        IConnext(_bridge).xcall{value: msg.value}(_domain, _recipient, _token, _delegate, _amount, _slippage, _data);
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}
