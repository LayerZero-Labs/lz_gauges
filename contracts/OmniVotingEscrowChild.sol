// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IL2LayerZeroDelegation.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract OmniVotingEscrowChild is NonblockingLzApp {
    mapping(address => uint) public locked__end; // -> end of lock period
    mapping(address => IVotingEscrow.Point) public userPoints; // -> balanceOf
    IVotingEscrow.Point public totalSupplyPoint; // -> totalSupply

    // Packet types for child chains:
    uint16 PT_USER = 0; // user balance and total supply update
    uint16 PT_TS = 1; // total supply update

    IL2LayerZeroDelegation public immutable delegationHook;

    event UserBalFromChain(uint16 srcChainId, address user, IVotingEscrow.Point userPoint, IVotingEscrow.Point totalSupplyPoint);
    event TotalSupplyFromChain(uint16 srcChainId, IVotingEscrow.Point totalSupplyPoint);

    constructor(address _lzEndpoint, address _delegationHook) NonblockingLzApp(_lzEndpoint) {
        require(_delegationHook != address(0x0), "OmniVotingEscrowChild: delegation hook cannot be 0x0");
        delegationHook = IL2LayerZeroDelegation(_delegationHook);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_USER) {
            _updateUserAndTotalSupplyFromChain(_srcChainId, _payload);
        } else if (packetType == PT_TS) {
            _updateTotalSupplyFromChain(_srcChainId, _payload);
        } else {
            revert("OmniVotingEscrowChild: unknown packet type");
        }
    }

    function _updateUserAndTotalSupplyFromChain(uint16 _srcChainId, bytes memory _payload) internal {
        (, address _userAddress, uint _lockedEnd, IVotingEscrow.Point memory _userPoint, IVotingEscrow.Point memory _totalSupplyPoint) = abi.decode(_payload, (uint16, address, uint, IVotingEscrow.Point, IVotingEscrow.Point));
        locked__end[_userAddress] = _lockedEnd;
        userPoints[_userAddress] = _userPoint;
        totalSupplyPoint = _totalSupplyPoint;

        delegationHook.onVeBalBridged(_userAddress);
        emit UserBalFromChain(_srcChainId, _userAddress, _userPoint, _totalSupplyPoint);
    }

    function _updateTotalSupplyFromChain(uint16 _srcChainId, bytes memory _payload) internal {
        (, IVotingEscrow.Point memory _totalSupplyPoint) = abi.decode(_payload, (uint16, IVotingEscrow.Point));
        totalSupplyPoint = _totalSupplyPoint;

        delegationHook.onVeBalSupplyUpdate();
        emit TotalSupplyFromChain(_srcChainId, _totalSupplyPoint);
    }

    function balanceOf(address _user) public view returns (uint) {
        return _getPointValue(userPoints[_user]);
    }

    function totalSupply() public view returns (uint) {
        return _getPointValue(totalSupplyPoint);
    }

    // external for testing
    function getPointValue(IVotingEscrow.Point memory _point) external view returns (uint) {
        return _getPointValue(_point);
    }

    // TODO confirm we do not need lockedEnd from the L1
    function _getPointValue(IVotingEscrow.Point memory _point) internal view returns (uint) {
        IVotingEscrow.Point memory p = _point;

        int128 bias = p.bias - (p.slope * int128(uint128(block.timestamp - p.ts)));
        return bias < 0 ? 0 : uint(uint128(bias));
    }
}
