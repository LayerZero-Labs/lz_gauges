# @version 0.3.1

# Mock used for testing transfer of point_history
struct Point:
    bias: int128
    slope: int128
    ts: uint256
    blk: uint256

epoch: public(uint256)
point_history: public(Point[100000000000000000000000000000])  # epoch -> unsigned point

user_point_epoch: public(HashMap[address, uint256])
user_point_history: public(HashMap[address, Point[1000000000]])  # user -> Point[user_epoch]


@external
def set_epoch(_epoch: uint256):
    self.epoch = _epoch

@external
def set_user_point_epoch(_addr: address, _epoch: uint256):
   self.user_point_epoch[_addr] = _epoch

@external
def set_point_history(_epoch: uint256, _point: Point):
   self.point_history[_epoch] = _point

@external
def set_user_point_history(_addr: address, _epoch: uint256, _point: Point):
  self.user_point_history[_addr][_epoch] = _point
