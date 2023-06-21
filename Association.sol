// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Meeting.sol";
import "./Donation.sol";
import "./TaxAuthority.sol";

contract Association {
    /*
     *Founding Protocol
     */
    string public foundingProtocolIPFSHash;

    /*
     * Approval of Association by Founders
     */

    bool public isRunning;
    address[] founders;
    mapping(address => bool) public foundersMapping;
    mapping(address => bool) public founderApproved;

    modifier onlyFounder() {
        require(foundersMapping[msg.sender]);
        _;
    }

    modifier onlyIfAssociationIsRunning() {
        require(isRunning, "Association not running");
        _;
    }

    uint256 public founderApprovedCounter;

    function approveAssociation() public onlyFounder {
        require(!founderApproved[msg.sender], "");
        require(!isRunning, "");
        founderApproved[msg.sender] = true;
        founderApprovedCounter += 1;

        if (founderApprovedCounter == founders.length) {
            isRunning = true;
        }
    }

    /*
     *  Statute
     */
    string public nameOfAssociation;
    string public purposeOfAssocation;

    mapping(string => uint256) public statuteData;
    string[] public statuteDataKeys;
    uint256 public membershipFeeDueDate;

    function getStatuteData(string memory _str) public view returns (uint256) {
        return statuteData[_str];
    }

    /*
     *  Make Donations
     */
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    uint256 tokenValue = 100;
    Donation donationContract;
    TaxAuthority taxAuthority;

    /*
     *  Creating Association
     */

    constructor(
        address _donationContract,
        address _taxAuthority,
        address[] memory _boardMembers,
        address[] memory _generalMembers,
        string memory _foundingProtocolIPFSHash,
        string memory _nameOfAssociation,
        string memory _purposeOfAssocation,
        uint256 _numMaxBoardMembers,
        uint256 _meetingDuration,
        uint256 _durationTillGeneralMeetingStart,
        uint256 _durationTillBoardMeetingStart
    ) {
        require(_boardMembers.length <= _numMaxBoardMembers, "");
        require((_boardMembers.length + _generalMembers.length) >= 1, "");
        require(
            keccak256(abi.encodePacked(_nameOfAssociation)) !=
                keccak256(abi.encodePacked("")),
            ""
        );
        require(
            keccak256(abi.encodePacked(_purposeOfAssocation)) !=
                keccak256(abi.encodePacked("")),
            ""
        );
        //require(_generalMeetingDuration >= 86400, "");
        //require(_boardMeetingDuration >= 86400, "");

        amountAuthorizedBoardMembers = 0;
        amountAuthorizedMembers = 0;
        isRunning = false;
        founderApprovedCounter = 0;

        foundingProtocolIPFSHash = _foundingProtocolIPFSHash;

        nameOfAssociation = _nameOfAssociation;
        purposeOfAssocation = _purposeOfAssocation;

        statuteData["minPercentageChairmanVote"] = 50;
        statuteDataKeys.push("minPercentageChairmanVote");

        statuteData["minPercentageBoardMeeting"] = 50;
        statuteDataKeys.push("minPercentageBoardMeetingVote");

        statuteData["minPercentageStatuteVote"] = 75;
        statuteDataKeys.push("minPercentageStatuteVote");

        statuteData["minPercentageLiquidationVote"] = 75;
        statuteDataKeys.push("minPercentageLiquidationVote");

        statuteData["minPercentagePurposeVote"] = 100;
        statuteDataKeys.push("minPercentagePurposeVote");

        statuteData["minPercentageNewMemberVote"] = 50;
        statuteDataKeys.push("minPercentageNewMemberVote");

        statuteData["minAmountQuorumGeneralMeeting"] = 1;
        statuteDataKeys.push("minPercentQuorumGeneralMeeting");

        statuteData["minAmountQuorumBoardMeeting"] = 1;
        statuteDataKeys.push("minPercentQuorumBoardMeeting");

        statuteData["minPercentageConfirmationForGM"] = 10;
        statuteDataKeys.push("minPercentageConfirmationForGM");

        statuteData["numMaxBoardMembers"] = _numMaxBoardMembers;
        statuteDataKeys.push("numMaxBoardMembers");

        statuteData["generalMeetingDuration"] = _meetingDuration;
        statuteDataKeys.push("generalMeetingDuration");

        statuteData["boardMeetingDuration"] = _meetingDuration;
        statuteDataKeys.push("boardMeetingDuration");

        statuteData[
            "durationTillGeneralMeetingStart"
        ] = _durationTillGeneralMeetingStart;
        statuteDataKeys.push("durationTillGeneralMeetingStart");

        statuteData[
            "durationTillBoardMeetingStart"
        ] = _durationTillBoardMeetingStart;
        statuteDataKeys.push("durationTillBoardMeetingStart");

        statuteData["membershipFee"] = 2000000000000000;
        statuteDataKeys.push("membershipFee");

        statuteData["membershipPaymentInterval"] = 2419200; //4 Wochen
        statuteDataKeys.push("membershipPaymentInterval");

        membershipFeeDueDate =
            block.timestamp +
            statuteData["membershipPaymentInterval"];

        for (uint256 i = 0; i < _generalMembers.length; i++) {
            addMember(_generalMembers[i]);
            founders.push(_generalMembers[i]);
            foundersMapping[_generalMembers[i]] = true;
        }

        for (uint256 i = 0; i < _boardMembers.length; i++) {
            addMember(_boardMembers[i]);
            addBoardMember(_boardMembers[i]);
            founders.push(_boardMembers[i]);
            foundersMapping[_boardMembers[i]] = true;
        }

        donationContract = Donation(_donationContract);
        taxAuthority = TaxAuthority(_taxAuthority);
    }

    /*
    *  End Creation of Association

    *  Start Member Management Logic
    */

    struct Member {
        address memberAddress;
        uint256 TimeOfNextFee;
        bool paid;
    }

    mapping(address => bool) public boardMemberMapping;
    mapping(address => bool) public memberMapping;
    mapping(address => Member) public memberStructMapping;

    address[] public members;
    address[] public boardMembers;

    uint256 public amountAuthorizedMembers;
    uint256 public amountAuthorizedBoardMembers;

    modifier onlyMember() {
        require(isMember(msg.sender), "");
        _;
    }

    modifier memberHasPaidFee() {
        require(hasPaidFee(msg.sender), "");
        _;
    }

    function isBoardMember(address addr) public view returns (bool) {
        if (boardMemberMapping[addr]) return true;
        else return false;
    }

    function isMember(address addr) public view returns (bool) {
        if (memberMapping[addr]) return true;
        else return false;
    }

    function hasPaidFee(address _addr) public view returns (bool) {
        return (memberStructMapping[_addr].TimeOfNextFee >
            membershipFeeDueDate);
    }

    /*function becomeMember() onlyIfAssociationIsRunning external {
        require(memberMapping[msg.sender] != true, 'sender is already a member');
        
        
        
    }*/

    function payMembershipFee()
        external
        payable
        onlyIfAssociationIsRunning
        onlyMember
    {
        require(!hasPaidFee(msg.sender), "");
        require(msg.value >= statuteData["membershipFee"], "");
        memberStructMapping[msg.sender].paid = true;
        memberStructMapping[msg.sender].TimeOfNextFee += statuteData[
            "membershipPaymentInterval"
        ];
        amountAuthorizedMembers += 1;
        if (boardMemberMapping[msg.sender]) {
            amountAuthorizedBoardMembers += 1;
        }

        incomes.push(Income(msg.sender, msg.value, block.timestamp, true));
    }

    function addMember(address _newMember) private {
        require(memberMapping[_newMember] != true, "");
        memberMapping[_newMember] = true;
        Member memory m = Member(_newMember, membershipFeeDueDate, false);
        memberStructMapping[_newMember] = m;
        members.push(m.memberAddress);
    }

    function addBoardMember(address _newBoardMember) private {
        require(memberMapping[_newBoardMember], "");
        require(!boardMemberMapping[_newBoardMember], "");
        boardMemberMapping[_newBoardMember] = true;
        boardMembers.push(_newBoardMember);
    }

    function checkAllMembersFeePayments() internal onlyIfAssociationIsRunning {
        if (block.timestamp >= membershipFeeDueDate) {
            amountAuthorizedBoardMembers = 0;
            amountAuthorizedMembers = 0;
            for (uint256 i = 0; i < members.length; i++) {
                if (
                    memberStructMapping[members[i]].TimeOfNextFee <
                    block.timestamp
                ) {
                    memberStructMapping[members[i]].paid = false;
                } else {
                    memberStructMapping[members[i]].paid = true;
                    amountAuthorizedMembers += 1;
                    if (boardMemberMapping[members[i]]) {
                        amountAuthorizedBoardMembers += 1;
                    }
                }
            }
            membershipFeeDueDate += statuteData["membershipPaymentInterval"];
        }
    }

    function endMembership() public onlyMember {
        memberMapping[msg.sender] = false;
        boardMemberMapping[msg.sender] = false;
        if (memberStructMapping[msg.sender].paid) {
            amountAuthorizedMembers -= 1;
            if (boardMemberMapping[msg.sender]) {
                amountAuthorizedBoardMembers -= 1;
            }
        }
        delete (memberStructMapping[msg.sender]);
    }

    function getTotalNumberMembers() public view returns (uint256) {
        return members.length;
    }

    struct NewMemberProposal {
        address newMember;
    }

    mapping(address => NewMemberProposal) public NewMemberProposalMapping;

    function becomeNewMember(
        string memory _description
    ) public onlyIfAssociationIsRunning {
        require(memberMapping[msg.sender] != true, "");
        Meeting m = createMeeting(Meeting.VOTINGTYPE.NEWMEMBER, _description);
        NewMemberProposalMapping[address(m)] = NewMemberProposal(msg.sender);
        m.setProposedNewMember(msg.sender);
    }

    /*
     *  End Member Management Logic
     */

    /*
     *Treasury Start
     */

    struct Income {
        address spender;
        uint256 amount;
        uint256 timeOfIncome;
        bool feePayment;
    }

    struct Expense {
        address receiver;
        uint256 amount;
        uint256 timeOfExpense;
        address boardMeeting;
    }

    Income[] public incomes;
    Expense[] public expenses;

    function deposit() public payable {
        incomes.push(Income(msg.sender, msg.value, block.timestamp, false));
    }

    function transferEther(
        address payable _to,
        uint256 _amount,
        address meeting
    ) private {
        _to.transfer(_amount);
        expenses.push(Expense(_to, _amount, block.timestamp, meeting));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
     *Treasury Functions End
     */

    /*
     *  Start Meeting Logic
     */

    struct MeetingStruct {
        string description;
        address proposer;
        uint256 expiry;
        Meeting.VOTINGTYPE votingType;
        bool alreadyExecuted;
    }

    Meeting[] public meetings;

    mapping(address => MeetingStruct) public meetingRegister;
    mapping(address => bool) public meetingRegistry;

    /*
     * Board Member Appointment/Dismissal
     */

    struct BoardMemberProposal {
        address proposedBoardMember;
    }

    mapping(address => BoardMemberProposal) public BoardMemberProposalMapping;

    modifier noBoardMemberVotingRunning() {
        if (meetings.length >= 1) {
            for (uint256 i = meetings.length - 1; i >= 0; i--) {
                MeetingStruct memory currentMeeting = meetingRegister[
                    address(meetings[i])
                ];
                if (
                    currentMeeting.votingType ==
                    Meeting.VOTINGTYPE.APPOINTBOARDMEMBER
                ) {
                    require(currentMeeting.expiry < block.timestamp, "");
                    break;
                }
            }
        }
        _;
    }

    function proposeBoardMemberAppointment(
        string memory _description,
        address _proposedBoardMember
    )
        public
        onlyIfAssociationIsRunning
        noBoardMemberVotingRunning
        onlyMember
        memberHasPaidFee
    {
        require(!boardMemberMapping[_proposedBoardMember], "");
        require(boardMembers.length < statuteData["numMaxBoardMembers"], "");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.APPOINTBOARDMEMBER,
            _description
        );
        BoardMemberProposalMapping[address(m)] = BoardMemberProposal(
            _proposedBoardMember
        );
        m.setProposedBoardMember(_proposedBoardMember);
    }

    function proposeBoardMemberDismissal(
        string memory _description,
        address _proposedBoardMember
    ) public onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        require(boardMemberMapping[_proposedBoardMember], "");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.DISMISSBOARDMEMBER,
            _description
        );
        BoardMemberProposalMapping[address(m)] = BoardMemberProposal(
            _proposedBoardMember
        );
        m.setProposedBoardMember(_proposedBoardMember);
    }

    /*
     * Purpose Change
     */
    struct PurposeChangeProposal {
        string proposedPurposeChange;
    }

    mapping(address => PurposeChangeProposal)
        public PurposeChangeProposalMapping;

    function proposePurposeChange(
        string memory _description,
        string memory _proposedNewPurpose
    ) public onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.PURPOSECHANGE,
            _description
        );
        PurposeChangeProposalMapping[address(m)] = PurposeChangeProposal(
            _proposedNewPurpose
        );
        m.setProposedPurpose(_proposedNewPurpose);
    }

    /*
     *Statute Change
     */
    struct StatuteProposal {
        uint256 statutePart;
        uint256 proposedValue;
    }

    mapping(address => StatuteProposal) StatuteProposalMapping;

    function proposeStatuteChange(
        string memory _description,
        uint256 _proposedStatuteData,
        uint256 _proposedNewValue
    ) external onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.STATUTECHANGE,
            _description
        );
        StatuteProposalMapping[address(m)] = StatuteProposal(
            _proposedStatuteData,
            _proposedNewValue
        );
        m.setProposedStatute(_proposedStatuteData, _proposedNewValue);
    }

    /*
     *  BoardMeeting
     */
    struct BoardMeetingProposal {
        address receiver;
        uint256 amountInWei;
    }

    mapping(address => BoardMeetingProposal) boardMeetingProposalMapping;

    function proposeBoardMeeting(
        string memory _description,
        address _to,
        uint256 _amountInWei
    ) external onlyIfAssociationIsRunning memberHasPaidFee {
        require(isBoardMember(msg.sender), "is not board member");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.BOARDMEETING,
            _description
        );
        boardMeetingProposalMapping[address(m)] = BoardMeetingProposal(
            _to,
            _amountInWei
        );
        m.setProposedBoardMeeting(_to, _amountInWei);
    }

    /*
     *  Liquidation
     */

    struct DissolutionProposal {
        uint256 TimeOfProposing;
        bool success;
    }

    mapping(address => DissolutionProposal) DissolutionProposalMapping;

    function proposeDissolution(
        string memory _description
    ) external onlyMember memberHasPaidFee {
        Meeting m = createMeeting(Meeting.VOTINGTYPE.LIQUIDATION, _description);
        DissolutionProposalMapping[address(m)] = DissolutionProposal(
            block.timestamp,
            false
        );
    }

    event newMeeting(MeetingStruct newMeeting);
    event executedMeetingDecision(MeetingStruct executedMeeting);

    function createMeeting(
        Meeting.VOTINGTYPE _votingType,
        string memory _description
    ) private returns (Meeting) {
        uint256 timeTillMeetingStartsInSeconds = block.timestamp +
            statuteData["durationTillBoardMeetingStart"];
        uint256 timeTillMeetingExpireInSeconds = timeTillMeetingStartsInSeconds +
                statuteData["generalMeetingDuration"];
        checkAllMembersFeePayments();
        Meeting m = new Meeting(
            _votingType,
            _description,
            timeTillMeetingStartsInSeconds,
            timeTillMeetingExpireInSeconds
        );
        meetings.push(m);
        MeetingStruct memory newM = MeetingStruct(
            _description,
            msg.sender,
            timeTillMeetingExpireInSeconds,
            _votingType,
            false
        );
        meetingRegister[address(m)] = newM;
        meetingRegistry[address(m)] = true;
        emit newMeeting(newM);
        return m;
    }

    modifier isMeeting() {
        require(meetingRegistry[msg.sender], "");
        _;
    }

    modifier notExecuted() {
        require(!meetingRegister[msg.sender].alreadyExecuted, "");
        _;
    }

    function endMeeting(
        Meeting.VOTINGTYPE votingType
    ) public isMeeting notExecuted {
        if (votingType == Meeting.VOTINGTYPE.BOARDMEETING) {
            BoardMeetingProposal memory proposal = boardMeetingProposalMapping[
                msg.sender
            ];
            transferEther(
                payable(proposal.receiver),
                proposal.amountInWei,
                msg.sender
            );
        } else if (votingType == Meeting.VOTINGTYPE.STATUTECHANGE) {
            string memory statutePart = statuteDataKeys[
                StatuteProposalMapping[msg.sender].statutePart
            ];
            statuteData[statutePart] = StatuteProposalMapping[msg.sender]
                .proposedValue;
        } else if (votingType == Meeting.VOTINGTYPE.APPOINTBOARDMEMBER) {
            boardMemberMapping[
                BoardMemberProposalMapping[msg.sender].proposedBoardMember
            ] = true;
            amountAuthorizedBoardMembers += 1;
        } else if (votingType == Meeting.VOTINGTYPE.DISMISSBOARDMEMBER) {
            boardMemberMapping[
                BoardMemberProposalMapping[msg.sender].proposedBoardMember
            ] = false;
            amountAuthorizedBoardMembers -= 1;
        } else if (votingType == Meeting.VOTINGTYPE.PURPOSECHANGE) {
            purposeOfAssocation = PurposeChangeProposalMapping[msg.sender]
                .proposedPurposeChange;
        } else if (votingType == Meeting.VOTINGTYPE.LIQUIDATION) {
            liquidateAssociation(msg.sender);
        } else if (votingType == Meeting.VOTINGTYPE.NEWMEMBER) {
            addMember(NewMemberProposalMapping[msg.sender].newMember);
        }

        meetingRegister[msg.sender].alreadyExecuted = true;
        emit executedMeetingDecision(meetingRegister[msg.sender]);
    }

    function liquidateAssociation(address meeting) private {
        uint256 balance = getBalance();
        checkAllMembersFeePayments();
        uint256 balanceChunk = balance / amountAuthorizedMembers;
        for (uint256 i = 0; i < members.length; i++) {
            if (memberStructMapping[members[i]].paid) {
                transferEther(
                    payable(address(members[i])),
                    balanceChunk,
                    meeting
                );
            }
        }
        isRunning = true;
    }

    /*
     *End Meeting Logic
     */

    /*
     *Donation & DONA TOKEN Logic
     */

    function donate() public payable {
        // Ensure that the contract has enough balance to transfer tokens
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
        // Transfer tokens from the contract to the caller
        uint256 tokenAmt = msg.value / tokenValue;
        donationContract.disburseDonaToken(msg.sender, tokenAmt);
    }

    function getFundersList() public view returns (address[] memory) {
        return funders;
    }

    function getFundedAmount(address _address) public view returns (uint256) {
        return addressToAmountFunded[_address];
    }

}