// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.30;

uint constant GWEI = 10 ** 9;
uint constant COIN = 10 ** 18;

contract ERC20ExtendedMinable {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint public totalSupply;
	
    string public name;
    string public symbol;
	string public image;
	string public description;
    uint8 public immutable decimals;
	
	bytes32 public immutable initialTarget;
    uint32 public immutable halvingInterval;
    uint32 public immutable epochDuration;
    uint16 public immutable targetSpacing;
    uint16 public immutable clampMin;
    uint16 public immutable clampMax;
    uint8 public immutable redeemFee;

    uint256 constant DIFF_THRESHOLD = 1000;
    uint256 immutable DIFF_CAP;
    
    bytes32 public parent;
    uint256[] public epochStack;
    uint256 public reward;
    uint256 public difficulty;
    uint32 public halvingCountdown;
    
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _image, 
        string memory _description, 
        uint256 _initialReward,
        uint32 _halvingInterval,
        uint32 _epochDuration,
        uint16 _targetSpacing,
        uint8 _redeemFee
    ) {
        name = _name;
        symbol = _symbol;
		image = _image;
		description = _description;
        decimals = 18;

		initialTarget = 0x0000ffff00000000000000000000000000000000000000000000000000000000;
        targetSpacing = _targetSpacing;
        halvingInterval = _halvingInterval;
        require(_epochDuration >= 10, "Window too small.");
        epochDuration = _epochDuration;
        clampMin = 25;
        clampMax = 400;

        DIFF_CAP = uint256(0x00000000ffff0000000000000000000000000000000000000000000000000000);
        require(DIFF_CAP <= type(uint256).max / GWEI && DIFF_CAP > DIFF_THRESHOLD, "DIFF_CAP overflow.");

        parent = bytes32(0);
        reward = _initialReward * COIN;
        halvingCountdown = _halvingInterval;
        difficulty = DIFF_THRESHOLD;

        require(_redeemFee < 100, "Redeem fee too high.");
        redeemFee = _redeemFee;
    }

    function currentTarget() public view returns (bytes32) {
        uint256 _initialTarget = uint256(initialTarget);
        uint256 _currentTarget = (_initialTarget * 1000) / difficulty;
        if (_currentTarget == 0)
            _currentTarget = 1;
        return bytes32(_currentTarget);
    }

    function _mint(
        address _to, 
        uint256 _value
    ) private {
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }

    function _burn(
        address _from, 
        uint256 _value
    ) private {
        require(balanceOf[_from] >= _value, "Balance too low.");
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
    }

    function _validateWork(bytes32 _hash) private view returns (bool) {
        uint256 _target = uint256(currentTarget());
        return uint256(_hash) < _target;
    }

    function _updateDifficulty() private {
        uint256 _n = epochStack.length;
        if (_n < epochDuration) return;

        uint256 _elapsed;
        for (uint256 _i = 1; _i < _n; ++_i) {
            _elapsed += epochStack[_i] - epochStack[_i - 1];
        }
        uint256 _average = _elapsed / (_n - 1);

        uint256 _multiple;
        if (_average == 0)
            _multiple = clampMax;
        else
            _multiple = (uint256(targetSpacing) * 100) / _average;

        if (clampMin > _multiple) 
            _multiple = clampMin;
        else if (clampMax < _multiple)
            _multiple = clampMax;

        difficulty = (difficulty * _multiple) / 100;
        if (difficulty > DIFF_CAP)
            difficulty = DIFF_CAP;
        else if (difficulty < DIFF_THRESHOLD) 
            difficulty = DIFF_THRESHOLD;
    }

    function _updateCounters() private {
        if (epochStack.length == epochDuration) {
            _updateDifficulty();
            delete epochStack;
        }

        if (halvingCountdown == 0) {
            reward /= 2;
            halvingCountdown = halvingInterval;
        } else
            halvingCountdown--;
    }

    function submitWork(
        bytes32 _hash,
        uint256 _nonce
    ) public payable {
        bytes32 _verify = keccak256(abi.encodePacked(
            parent,
            msg.sender, 
            _nonce
        ));
        uint256 _fee = difficulty * GWEI;
        require(_verify == _hash && _validateWork(_hash) && msg.value >= _fee, "Orphaned.");
        _updateCounters();
        epochStack.push(block.timestamp);
        parent = _hash;
        _mint(msg.sender, reward);
        uint256 _change = msg.value - _fee;
        if (_change > 0)
            payable(msg.sender).transfer(_change);
    }

    function redeemTokens(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Balance too low.");
        uint256 _gross = (address(this).balance * _amount) / totalSupply;
        uint256 _value = (_gross * (100 - redeemFee)) / 100;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_value);
    }

    function transfer(
        address _to, 
        uint256 _value
    ) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Balance too low.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public returns (bool) {
        require(balanceOf[_from] >= _value, "Balance too low.");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low.");
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;   
    }
    
    function approve(
        address _spender, 
        uint256 _value
    ) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;   
    }
}
