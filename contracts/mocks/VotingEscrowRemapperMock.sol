// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/IVotingEscrowRemapper.sol";

contract VotingEscrowRemapperMock is IVotingEscrowRemapper {
    IVotingEscrow public getVotingEscrow;

    mapping(uint16 => mapping(address => address)) public _localToRemoteAddressMap;

    constructor(address _votingEscrow) {
        getVotingEscrow = IVotingEscrow(_votingEscrow);
    }

    function getRemoteUser(address _localUser, uint16 _dstChainId) external view returns (address) {
        return _localToRemoteAddressMap[_dstChainId][_localUser];
    }

    function setRemoteUser(address _remoteUser, uint16 _dstChainId) external {
        _localToRemoteAddressMap[_dstChainId][msg.sender] = _remoteUser;
    }
}
