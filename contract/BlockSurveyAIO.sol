pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BlockSurveyAIO {
    string public name = "SurveyTokenBeta";
    string public symbol = "SVTb";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000000000000000000000000;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // token event
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    // blocksurvey event
    event createdPoll(address creater, uint256 pollid);
    event JoinedPoll(address user, uint256 pollid, uint256 time);
    event createdAnswer(address user, uint256 pollid, uint256 answerid);

    // blocksurvey modifier
    modifier pollJoinLimitReached(uint pollID) {
        if (pollList[pollID].answerCount >= pollList[pollID].answerLimit) revert("Poll join limit reached!");
        _;
    }
    modifier pollTimeoutReached(uint pollID) {
        if (pollList[pollID].endTime < now) revert("Poll timeout reached!");
        _;
    }
    modifier pollStillAlive(uint pollID) {
        if (pollList[pollID].isFinished) revert("Poll is not alive!");
        _;
    }
    modifier pollJoined(uint pollID, address userAddress) {
        for(uint i = 0; i < pollList[pollID].answerCount; i++) {
            if (pollList[pollID].participant[i] == userAddress) _;
        }
        revert("User not joined!");
    }
    modifier pollOwner(uint pollID) {
        if (pollList[pollID].creator != msg.sender) revert("Not owner!");
        _;
    }

    modifier userJoined(address userAddress) {
        if(!(userList[userAddress].userID < 0)) revert("User arleady joined!");
        _;
    }

    modifier userNotJoined(address userAddress) {
        if(userList[userAddress].userID < 0) revert("User not joined!");
        _;
    }

    modifier adminOnly() {
        // if (msg.sender != admin) revert("not admin");
        if (msg.sender != msg.sender) revert("User is not admin!");
        _;
    }

    
    // ERC20 logic part. whole contract constructors are here.

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    /**
    *  Blocksurvey part
    *  events & modifiers are written at top.
    *  check older logs to find out ERC20 remarks.
    *  SweetLab GAZUA!!!!!!!!!
    */

    struct Poll{
        address creator; 
        uint256 pollID;

        uint256 startTime;
        uint256 endTime;
        uint256 answerLimit;
        uint256 answerCount;

        bool isFinished;
        string questionSheet;

        uint256 deposit;

        mapping(uint256 => address) participant; // 누구든지 확인할 수 있음. 해당 참여자의 참여 여부 확인 가능
        mapping(uint256 => string) answerSheet;  // 접근 권한 제한 필요. 개발자만 제한적으로 조회할 수 있는 함수 개발 예정.
    }

    // User Part
    struct UserData{
        uint256 userID;        // 내부 처리용 ID, 보안성과 익명성 강화용 (추후 삭제 가능)
        uint256 userScore;     // 사용자 평점 (잘못된 응답 등 피드백)
        bool isConfirmed;      // 실명인증 여부
    }

    mapping (uint256 => Poll) private pollList;      // 모든 설문조사 목록
    mapping (address => UserData) private userList;  // 내부 처리용 사용자 정보
    
    // Main Logic Part
    uint256 private pollCount = 0;
    uint256 private userCount = 0;

    /**
    * Token part
    * - in this part, can connect to SurveyToken contract which is arleady deployed
    * - can be used in payment progress
    * - contr addr : 0xd3dac111b5f4340453cbfa45b0bd0de6de135379
    */

    function depositToken(uint _value)
        internal
    {
        transfer(0x8cad9b4941aafb67b5a5e6dea657db2d4ea7b757, _value);
        // 수수료를 재단에 내는 함수, 전체 보상량의 1/1000
    }


    function sendToken(address[] _to, uint[] _value)
        internal
    {
        for(uint i = 0; i < _to.length; i++) transfer(_to[i], _value[i]);

        // 참여자들에게 보상 배분하는 함수
        // 여기에 결과에 대한 추가 수수료 납부하는 것 넣어도 됨.
    }

    // 마무리 이후 결과 공개 로직 필요함. 


    /**
    * User part
    * - in this part, I've added few functions for user adding, confirming
    * - can be used in registration progress
    */

    function addUser()
        public

        userNotJoined(msg.sender) // 사용자 인증 시스템과 연동 고려해야 함. 실명인증 플래그 방식이 좋을 듯.

        returns(bool isSuccessed, uint256 userID)
    {
        userList[msg.sender] = UserData(userCount, 100, false);

        isSuccessed = true;
        userID = userCount++;
    }

    function confirmUser(address user)
        public

        userJoined(user)
        adminOnly()

        returns(bool isSuccessed)
    {
        userList[user].isConfirmed = true;
        isSuccessed = true;
    }

    /**
    * Poll part
    * - in this part, I've added few functions for poll creating, getting poll & question.
    * - can be used in poll creation progress
    * - joining logic is merged to createAnswer method
    */

    // fee는 전체 지불할 양의 1인당 fee로 요청해야 함.
    // 1인에 해당하는 fee가 기본 플랫폼 이용 수수료로 지불됨.
    function createPoll(uint256 answerLimit, uint256 timeLimit, string questionSheet, uint256 fee)
        public
        payable
        returns(uint256 pollID) 
    {
        //Poll(msg.sender, pollCount, block.timestamp, (block.timestamp + timeLimit), answerLimit, 0, false, questionSheet);
        depositToken(fee);

        uint256 time = now;
        uint256 endTime = time + timeLimit;

        pollList[pollCount] = (Poll(msg.sender, pollCount, time, endTime, answerLimit, 0, false, questionSheet, fee));
        pollID = pollCount++;
    }

    function getPoll(uint256 pollID)
        public
        view
        returns(
        address creator, 
        uint256 starttime,
        uint256 endTime,
        uint256 answerLimit,
        uint256 questionCount,
        uint256 answerCount,
        uint256 deposit,
        bool isFinished,
        string questionSheet
        )
    {
        creator = pollList[pollID].creator;
        starttime = pollList[pollID].startTime;
        endTime = pollList[pollID].endTime;
        answerLimit = pollList[pollID].answerLimit;
        answerCount = pollList[pollID].answerCount;
        deposit = pollList[pollID].deposit;
        isFinished = pollList[pollID].isFinished;
        questionSheet = pollList[pollID].questionSheet;
    }

    function finishPoll(uint256 pollID)
        public
        payable

        pollOwner(pollID)

        returns(bool isSuccessed)
    {
        address[] memory receivers = new address[](pollList[pollID].answerCount);
        uint256[] memory values = new uint256[](pollList[pollID].answerCount);

        for(uint i = 0; i < pollList[pollID].answerCount; i++)
        {
            receivers[i] = (pollList[pollID].participant[i]);
            values[i] = (pollList[pollID].deposit);
        }
        sendToken(receivers, values);
        pollList[pollID].isFinished = true;
    }

    function getQuestion(uint256 pollID)
        public
        view
        returns(string question)
    {
        question = pollList[pollID].questionSheet;
        // Question need to be fixed for JSON support
    }



    /**
    * answer part
    * - in this part, I've added few functions for user adding, confirming
    * - can be used in registration progress
    */

    function createAnswer(uint256 pollID, string answer) 
        public
        payable
        
        pollJoinLimitReached(pollID)
        pollTimeoutReached(pollID)
        pollStillAlive(pollID)
        
        returns(bool result, uint answerID)
    {
        pollList[pollID].participant[pollList[pollID].answerCount] = msg.sender;
        pollList[pollID].answerSheet[pollList[pollID].answerCount] = answer;

        answerID = pollList[pollID].answerCount;
        result = true;

        pollList[pollID].answerCount++;
        // answer JSON datatype definition
    }

    function getAnswer(uint256 pollID, uint256 answerID)
        public
        view
        returns(string question)
    {
        question = pollList[pollID].answerSheet[answerID];
    }
}