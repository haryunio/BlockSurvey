pragma solidity ^0.4.23;

contract BlockSurvey{
 
    /////////////////////////////////////////////
    ////////Answer Part//////////////////////////
    /////////////////////////////////////////////
    
    struct Answer{                //개별 질문에 대한 답변
        uint8 answerIndex;
        string answerData;
    }
    struct AnswerSheet{           //설문에 대한 답변 모음
        uint256 sheetID;
        userData userdata;
        mapping (uint256 => Answer) answers;
    }


    /////////////////////////////////////////////
    ////////Question Part////////////////////////
    /////////////////////////////////////////////

    struct descQuestion{          //서술형 질문
        bool isCreated;
        uint8 questionIndex;
        string question;
    }
    struct choiceQuestion{        //선택형 질문
        bool isCreated;
        uint8 questionIndex;
        string question;
        string[] choices;
    }
    struct questionSheet{         //질문지
        uint8 questionCount;
        mapping (uint256 => descQuestion) descQuestions;
        mapping (uint256 => choiceQuestion) choiceQuestions;
    }

    /////////////////////////////////////////////
    ////////Poll Part////////////////////////////
    /////////////////////////////////////////////

    struct Poll{                  //설문
        address creator;
        uint256 pollID;

        uint256 answerLimit;

        uint256 starttime;
        uint256 timelimit;

        QuestionSheet questionSheet;
        mapping (uint256 => AnswerSheet) answerSheet;
    }

    /////////////////////////////////////////////
    ////////User Part////////////////////////////
    /////////////////////////////////////////////

    struct UserData{
        address userAddress;   //사용자 지갑 주소
        uint256 userID;        //내부 처리용 ID, 보안성과 익명성 강화용
        uint256 userScore;     //사용자 평점 (잘못된 응답 등 피드백)
    }

    /////////////////////////////////////////////
    ////////Mapping Part/////////////////////////
    /////////////////////////////////////////////

    mapping (uint256 => Poll) private pollList;     //모든 설문조사 목록
    mapping (address => UserData) private userData; //내부 처리용 사용자 정보


    /////////////////////////////////////////////
    ////////Main Logic Part//////////////////////
    /////////////////////////////////////////////

    uint256 private pollCount;

    constructor() public {
        pollCount = 0;
    }

    function createPoll(uint256 questionCount, uint256 timeLimit) public payable returns(uint256 pollID) {
        pollList[pollCount] = Poll(msg.sender, questionCount, )
    }

    function joinPoll(uint256 pollID) public payable returns(uint256 receipt){
        uint256 tmp = pollID;
        tmp++;
        receipt = 1;
    }

    function createAnswer(uint256 answerID) public payable returns(bool result){


        result = true;
    }

}