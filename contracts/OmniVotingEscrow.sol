// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
    }

    function epoch() external view returns(uint256);
    function user_point_epoch(address _user) external returns (uint256);
    function user_point_history(address _user, uint256 _epoch) external returns (Point memory);
    function point_history(uint256 _epoch) external returns (Point memory);
}

contract OmniVotingEscrow is NonblockingLzApp {

    address public immutable votingEscrow;
    mapping(address => IVotingEscrow.Point) public userPoints; // corresponds to balanceOf
    IVotingEscrow.Point public totalSupplyPoint; // coresponds to totalSupply

    uint16 PT_USER = 0; // Packet type of user balance, including totalSupply
    uint16 PT_TS = 1; // Packet type of just total supply update

    event UserBalToChain(uint16 dstChainId, address user, IVotingEscrow.Point userPoint, IVotingEscrow.Point totalSupplyPoint);
    event TotalSupplyToChain(uint16 dstChainId, IVotingEscrow.Point totalSupplyPoint);

    constructor(address _lzEndpoint, address _votingEscrow) NonblockingLzApp(_lzEndpoint) {
        votingEscrow = _votingEscrow;
    }

    function estimateSendUser(uint16 _dstChainId, address _user, bool _useZro, bytes calldata _adapterParams) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory lzPayload = abi.encode(PT_USER, address(0x0), userPoints[_user], totalSupplyPoint);
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    function estimateSendTotalSupply(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory lzPayload = abi.encode(PT_TS, totalSupplyPoint);
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    function sendUserVeBalance(address _user, uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        // get current user point
        uint256 userEpoch = IVotingEscrow(votingEscrow).user_point_epoch(_user);
        IVotingEscrow.Point memory uPoint = IVotingEscrow(votingEscrow).user_point_history(_user, userEpoch);

        // get current totalSupply point
        uint256 totalSupplyEpoch = IVotingEscrow(votingEscrow).epoch();
        IVotingEscrow.Point memory tsPoint = IVotingEscrow(votingEscrow).point_history(totalSupplyEpoch);

        bytes memory lzPayload = abi.encode(PT_USER, _user, uPoint, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit UserBalToChain(_dstChainId, _user, uPoint, tsPoint);
    }

    function sendTotalSupply(uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        // get current totalSupply point
        uint256 totalSupplyEpoch = IVotingEscrow(votingEscrow).epoch();
        IVotingEscrow.Point memory tsPoint = IVotingEscrow(votingEscrow).point_history(totalSupplyEpoch);

        bytes memory lzPayload = abi.encode(PT_TS, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit TotalSupplyToChain(_dstChainId, tsPoint);
    }

    function _nonblockingLzReceive(uint16 /*_srcChainId*/, bytes memory /*_srcAddress*/, uint64 /*_nonce*/, bytes memory _payload) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_USER) {
            // TODO bytes or address?
            (, address _userAddress, IVotingEscrow.Point memory _userPoint, IVotingEscrow.Point memory _totalSupplyPoint) = abi.decode(_payload, (uint16, address, IVotingEscrow.Point, IVotingEscrow.Point));
            userPoints[_userAddress] = _userPoint;
            totalSupplyPoint = _totalSupplyPoint;

        } else if (packetType == PT_TS) {
            (, IVotingEscrow.Point memory _totalSupplyPoint) = abi.decode(_payload, (uint16, IVotingEscrow.Point));
            totalSupplyPoint = _totalSupplyPoint;

        } else {
            revert("OmniVotingEscrow: unknown packet type");
        }

        // TODO add events for receive?
    }

    function balanceOf(address _user) public view returns (uint256) {
        return _getPointValue(userPoints[_user]);
    }

    function totalSupply() public view returns (uint256) {
        return _getPointValue(totalSupplyPoint);
    }

    function _getPointValue(IVotingEscrow.Point memory _point) internal view returns (uint256) {
        IVotingEscrow.Point memory p = _point;

        int128 bias = p.bias - p.slope * int128(uint128(block.timestamp - p.ts));

        if (bias < 0) {
            return 0;
        } else {
            return uint256(uint128(bias));
        }
    }
}
