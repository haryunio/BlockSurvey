pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract BlockSurvey{

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

        mapping(address => uint256) participant; // 누구든지 확인할 수 있음. 해당 참여자의 참여 여부 확인 가능
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
        if (pollList[pollID].endTime >= block.timestamp) revert("Poll timeout reached!");
        _;
    }
    modifier pollStillAlive(uint pollID) {
        if (pollList[pollID].isFinished) revert("Poll is not alive!");
        _;
    }
    modifier pollJoined(uint pollID) {
        if (pollList[pollID].participant[msg.sender] < 0) revert("Poll is not alive!");
        _;
    }
    modifier userJoined(address userAddress) {
        if (userList[userAddress].userID < 0) revert("User arleady joined!");
        _;
    }
    modifier adminOnly() {
        // if (msg.sender != admin) revert("not admin");
        if (msg.sender != msg.sender) revert("User is not admin!");
        _;
    }



    /**
    * User part
    * - in this part, I've added few functions for user adding, confirming
    * - can be used in registration progress
    */

    function addUser()
        public

        userJoined(msg.sender) // 사용자 인증 시스템과 연동 고려해야 함. 실명인증 플래그 방식이 좋을 듯.

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

    function createPoll(uint256 answerLimit, uint256 timeLimit, string questionSheet)
        public
        payable
        returns(uint256 pollID) 
    {
        //Poll(msg.sender, pollCount, block.timestamp, (block.timestamp + timeLimit), answerLimit, 0, false, questionSheet);

        pollList[pollCount] = (Poll(msg.sender, pollCount, block.timestamp, (block.timestamp + timeLimit), answerLimit, 0, false, questionSheet));
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
        string questionSheet
        )
    {
        creator = pollList[pollID].creator;
        starttime = pollList[pollID].startTime;
        endTime = pollList[pollID].endTime;
        answerLimit = pollList[pollID].answerLimit;
        answerCount = pollList[pollID].answerCount;
        questionSheet = pollList[pollID].questionSheet;
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
        pollJoined(pollID)

        returns(bool result, uint answerID)
    {
        pollList[pollID].participant[msg.sender] = answerID;

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