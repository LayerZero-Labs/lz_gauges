// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IVotingEscrow.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract OmniVotingEscrow is NonblockingLzApp {

    address public immutable votingEscrow;

    // Packet types for child chains:
    uint16 PT_USER = 0; // user balance and total supply update
    uint16 PT_TS = 1; // total supply update

    event UserBalToChain(uint16 dstChainId, address user, IVotingEscrow.Point userPoint, IVotingEscrow.Point totalSupplyPoint);
    event TotalSupplyToChain(uint16 dstChainId, IVotingEscrow.Point totalSupplyPoint);

    constructor(address _lzEndpoint, address _votingEscrow) NonblockingLzApp(_lzEndpoint) {
        votingEscrow = _votingEscrow;
    }

    // TODO maybe get rid of lzapp in favour of only send functions?
    function _nonblockingLzReceive(uint16 /*_srcChainId*/, bytes memory /*_srcAddress*/, uint64 /*_nonce*/, bytes memory /*_payload*/) internal virtual override {
        revert("OmniVotingEscrow: cannot receive lzMsgs");
    }

    function estimateSendUserBalance(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory lzPayload = abi.encode(PT_USER, address(0x0), IVotingEscrow.Point(0,0,0,0), IVotingEscrow.Point(0,0,0,0));
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    function estimateSendTotalSupply(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory lzPayload = abi.encode(PT_TS, IVotingEscrow.Point(0,0,0,0));
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    // always send total supply along with a user update
    function sendUserBalance(address _user, uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        uint256 userEpoch = IVotingEscrow(votingEscrow).user_point_epoch(_user);
        IVotingEscrow.Point memory uPoint = IVotingEscrow(votingEscrow).user_point_history(_user, userEpoch);

        uint256 totalSupplyEpoch = IVotingEscrow(votingEscrow).epoch();
        IVotingEscrow.Point memory tsPoint = IVotingEscrow(votingEscrow).point_history(totalSupplyEpoch);

        bytes memory lzPayload = abi.encode(PT_USER, _user, uPoint, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit UserBalToChain(_dstChainId, _user, uPoint, tsPoint);
    }

    // TODO check if we need to call checkpoint() before retrieving totalSupply re. "slope_changes"
    function sendTotalSupply(uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        uint256 totalSupplyEpoch = IVotingEscrow(votingEscrow).epoch();
        IVotingEscrow.Point memory tsPoint = IVotingEscrow(votingEscrow).point_history(totalSupplyEpoch);

        bytes memory lzPayload = abi.encode(PT_TS, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit TotalSupplyToChain(_dstChainId, tsPoint);
    }
}
