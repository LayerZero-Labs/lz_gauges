// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk; // TODO get rid of blk?
    }

    function epoch() external view returns(uint256);
    function user_point_epoch(address _user) external returns (uint256);
    function user_point_history(address _user, uint256 _epoch) external returns (Point memory);
    function point_history(uint256 _epoch) external returns (Point memory);
    function checkpoint() external;
}