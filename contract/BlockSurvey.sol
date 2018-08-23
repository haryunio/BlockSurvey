pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract BlockSurvey{

    // Answer Part
    struct Answer{                // 개별 질문에 대한 답변
        uint8 answerIndex;        // answer index
        string answerContent;     // answer content (JSON type)
    }

    // Poll Part
    struct Poll{                  // 설문(Poll 작업분)
        address creator;
        uint256 pollID;
        uint256 starttime;
        uint256 timelimit;
        uint256 answerLimit;
        uint256 questionCount;
        uint8 answerCount;      // 답변 개수

        mapping (uint8 => string) questionSheet;  // String 기반 단일 Mapping으로 질문 json 저장하기
        mapping (uint8 => string[]) answerSheet;    // 2중 mapping 사용. uint8로 답지 매핑 찾아가고, string array 내에 응답 정보 저장
    }

    // User Part

    struct UserData{
        address userAddress;   // 사용자 지갑 주소
        uint256 userID;        // 내부 처리용 ID, 보안성과 익명성 강화용
        uint256 userScore;     // 사용자 평점 (잘못된 응답 등 피드백)
    }

    // mapping (uint256 => Poll) private pollList;  // 모든 설문조사 목록
    Poll[] pollList;
    mapping (address => UserData) private userData; // 내부 처리용 사용자 정보
    
    // Main Logic Part
    uint256 private pollCount;

    constructor() public {
        pollCount = 0;
    }

    // to-do: solidity fix needed to fix all of the struct-type sources.

    function createPoll(uint256 answerLimit, uint256 timeLimit) public payable returns(uint256 pollID) {
        pollList.push(Poll(msg.sender, pollCount, block.timestamp, timeLimit, answerLimit, 0, 0));
        pollCount = pollCount + 1;
        pollID = pollCount;
    }

    function joinPoll(uint256 pollID) public payable returns(uint256 receipt){
        uint256 tmp = pollID;
        tmp++;

        // poll joining logic needed

        receipt = 1;
    }

    function getPoll(uint256 pollID) public view returns(
        address creator,
        uint256 starttime,
        uint256 timelimit,
        uint256 answerLimit,
        uint256 questionCount,
        uint256 answerCount
    ){
        creator = pollList[pollID].creator;
        starttime = pollList[pollID].starttime;
        timelimit = pollList[pollID].timelimit;
        answerLimit = pollList[pollID].answerLimit;
        questionCount = pollList[pollID].questionCount;
        answerCount = pollList[pollID].answerCount;
    }

    function createQuestions(uint256 pollID, uint8 questionCount, string[] questionContent
        ) public payable returns(
            bool isSuccessed
        ){
        pollList[pollID].questionCount = questionCount;
        for(uint8 i = 0; i < questionCount; i++) pollList[pollID].questionSheet[i] = questionContent[i];
        isSuccessed = true;
    }

    function getQuestion(uint256 pollID, uint8 questionNumber) public view returns(
        string question
        ){
        question = pollList[pollID].questionSheet[questionNumber];
        // returns correct question data
    }


    // to-do : answer processing logic - get answerData, return answerID, etc...
    function createAnswer(uint256 pollID, string[] answerList) public payable returns(
            bool result,
            uint answerID
        ){
        if(pollList[pollID].answerCount >= pollList[pollID].answerLimit) revert("Answer Limit");
        // sender logging logic needed
        pollList[pollID].answerSheet[pollList[pollID].answerCount] = answerList;
        answerID = pollList[pollID].answerCount;

        pollList[pollID].answerCount = pollList[pollID].answerCount + 1;
        result = true;
    }
    
    function getAnswer(uint256 pollID, uint8 answerID) public view returns(
        string[] question
        ){
        question = pollList[pollID].answerSheet[answerID];
    }
}