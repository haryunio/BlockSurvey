pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BlockSurveyAIO {
    // Public variables of the token
    string public name = "SurveyToken";
    string public symbol = "SVT";
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = 100000000000000000000000000000;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    event createdPoll(address creater, uint256 pollid);
    event JoinedPoll(address user, uint256 pollid, uint256 time);
    event createdAnswer(address user, uint256 pollid, uint256 answerid);

    // Poll Part
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

    modifier pollJoinLimitReached(uint pollID) {
        if (pollList[pollID].answerCount >= pollList[pollID].answerLimit) revert("Poll join limit reached!");
        _;
    }
    modifier pollTimeoutReached(uint pollID) {
        if (pollList[pollID].endTime < block.timestamp) revert("Poll timeout reached!");
        _;
    }
    modifier pollStillAlive(uint pollID) {
        if (pollList[pollID].isFinished) revert("Poll is not alive!");
        _;
    }
    modifier pollJoined(uint pollID, address userAddress) {
        for(uint i = 0; i < pollList[pollID].answerCount; i++)
        {
            if (pollList[pollID].participant[i] == userAddress) _;
        }
        revert("User not joined!");
    }
    modifier pollOwner(uint pollID) {
        if (pollList[pollID].creator != msg.sender) revert("Not owner!");
        _;
    }

    modifier userJoined(address userAddress) {
        if(userList[userAddress].userID < 0) revert("User not joined!");
        _;
    }

    modifier userNotJoined(address userAddress) {
        if(!(userList[userAddress].userID < 0)) revert("User arleady joined!");
        _;
    }

    modifier adminOnly() {
        // if (msg.sender != admin) revert("not admin");
        if (msg.sender != msg.sender) revert("User is not admin!");
        _;
    }


    
    /**
    * Token part
    * - in this part, can connect to SurveyToken contract which is arleady deployed
    * - can be used in payment progress
    * - token addr : 0xa80aded81471f756de195480f286aa216a09a0c8
    * - contr addr : 0xd3dac111b5f4340453cbfa45b0bd0de6de135379
    */

    function depositToken(uint _value)
        internal
    {
        transfer(0x8cad9b4941aafb67b5a5e6dea657db2d4ea7b757, _value);
    }

    function sendToken(address[] _to, uint[] _value, uint _valuesum)
        internal
    {
        transferFrom(0x8cad9b4941aafb67b5a5e6dea657db2d4ea7b757, msg.sender, _valuesum);

        for(uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _value[i]);
        }
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

    function createPoll(uint256 answerLimit, uint256 timeLimit, string questionSheet, uint256 fee)
        public
        payable
        returns(uint256 pollID) 
    {
        //Poll(msg.sender, pollCount, block.timestamp, (block.timestamp + timeLimit), answerLimit, 0, false, questionSheet);
        depositToken(fee);

        pollList[pollCount] = (Poll(msg.sender, pollCount, block.timestamp, (block.timestamp + timeLimit), answerLimit, 0, false, questionSheet, fee));
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

        pollStillAlive(pollID)
        pollOwner(pollID)

        returns(bool isSuccessed)
    {
        address[] receivers;
        uint256[] values;

        for(uint i = 0; i < pollList[pollID].answerCount; i++)
        {
            receivers.push(pollList[pollID].participant[i]);
            values.push(pollList[pollID].deposit / pollList[pollID].answerCount);
        }
        sendToken(receivers, values, pollList[pollID].deposit);
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