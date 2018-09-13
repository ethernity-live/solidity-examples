pragma solidity ^0.4.11;

    /*********************************************************************************
     *********************************************************************************
     *
     * Ethereum Ballot System
     * Ballot smart contract
     *
     *********************************************************************************
     ********************************************************************************/

// Ballot
contract Ballot {

    /*********************************************************************************
     *
     * Data
     *
     *********************************************************************************/

    // creator of the ballot
    address public electionAuthority;

    // deadline for the ballot
    uint public deadline;
    bool ballotClosed = false;

    // a single voter.
    struct Voter {
        bool    canVote;         // if true, this person can vote
        bool    voted;           // if true, this person already voted
    }

    // a 'Voter' struct for each possible address
    mapping(address => Voter) public voters;

    // a single candidate
    struct Candidate {
        address runningAddress;  // candidate address
        bytes32 name;            // short name (up to 32 bytes)
        bool    canRun;          // if true, this person can run in the ballot
        uint    voteCount;       // number of accumulated votes
    }

    // a 'Candidate' struct for each possible address
    mapping(address => Candidate) public candidates;

    // an array of 'Candidates' created because structures cannot be traversed
    uint candidateIndex = 0;
    Candidate[4] candidatesArray;

    // candidate with maximum number of votes
    address winningCandidateAddress;
    uint    winningCandidateVotes;

    /*********************************************************************************
     *
     * Validations
     *
     *********************************************************************************/

    modifier onlyElectionAuthority { if (msg.sender != electionAuthority) throw; _; }

    modifier afterDeadline() { if (now >= deadline) throw; _; }

    /*********************************************************************************
     *
     * Events
     *
     *********************************************************************************/

    event BallotCreated(address from);

    event DurationSet(uint durationInHours);

    event RegisterVoter(address voterAddress);

    event Vote(address candidateAddress);

    event RegisterCandidate(bytes32 candidateName, address candidateAddress);

    event GiveRightToVote(address voter);

    event GiveRightToRun(address candidate);

    /*********************************************************************************
     *
     * Constructor
     *
     *********************************************************************************/

    /// constructor - create a new ballot
    function Ballot() {
        electionAuthority = tx.origin;
        // generate event
        BallotCreated(electionAuthority);
    }

    /*********************************************************************************
     *
     * Functions for Election Authority
     *
     *********************************************************************************/

    function setDuration(uint durationInHours) onlyElectionAuthority afterDeadline {
        deadline = now + durationInHours * 60 minutes;
        DurationSet(durationInHours);
    }

    // give 'Voter' the right to vote on this ballot
    function giveRightToVote(address voter) onlyElectionAuthority afterDeadline {
        require(!voters[voter].voted);
        voters[voter].canVote = true;
        // generate event
        GiveRightToVote(voter);
    }

    // give 'Candidate' the right to run on this ballot
    function giveRightToRun(address candidate) onlyElectionAuthority afterDeadline {
        candidates[candidate].canRun = true;
        // generate event
        GiveRightToRun(candidate);
    }

    /*********************************************************************************
     *
     * Functions for Candidates
     *
     *********************************************************************************/

    // Register yourself to run as a candidate
    //function registerCandidate(bytes32 candidateName, address candidateAddress)  {
    function registerCandidate(bytes32 candidateName)  {
        // save in structure
        address candidateAddress = tx.origin;
        candidates[candidateAddress].runningAddress = candidateAddress;
        candidates[candidateAddress].name           = candidateName;
        candidates[candidateAddress].canRun         = false;
        candidates[candidateAddress].voteCount      = 0;
        // save in array
        candidatesArray[candidateIndex].runningAddress = candidateAddress;
        candidatesArray[candidateIndex].name           = candidateName;
        candidatesArray[candidateIndex].canRun         = false;
        candidatesArray[candidateIndex].voteCount      = 0;
        // save in array
        candidateIndex++;
        // generate event
        RegisterCandidate(candidateName, candidateAddress);
    }

    /*********************************************************************************
     *
     * Functions for Voters
     *
     *********************************************************************************/

    // Register yourself to vote
    //function registerVoter(address voterAddress) {
    function registerVoter() {
        address voterAddress = tx.origin;
        voters[voterAddress].canVote = false;
        voters[voterAddress].voted   = false;
        // generate event
        RegisterVoter(voterAddress);
    }

    // Give your vote to candidate
    function voteForCandidate(address candidateAddress) afterDeadline {
        Voter sender = voters[tx.origin];
        require(sender.canVote);
        require(!sender.voted);
        sender.voted = true;
        candidates[candidateAddress].voteCount += 1;
        if (candidates[candidateAddress].voteCount > winningCandidateVotes) {
            winningCandidateAddress = candidateAddress;
            winningCandidateVotes   = candidates[candidateAddress].voteCount;
        }
        // generate event
        Vote(candidateAddress);
    }

    /*********************************************************************************
     *
     * Functions to get Ballot results
     *
     *********************************************************************************/

    // returns ballot count
    function getVotes() constant returns(bytes32 name0, address address0, uint votes0,
                                         bytes32 name1, address address1, uint votes1,
                                         bytes32 name2, address address2, uint votes2,
                                         bytes32 name3, address address3, uint votes3) {
        name0    = candidatesArray[0].name;
        address0 = candidatesArray[0].runningAddress;
        votes0   = candidatesArray[0].voteCount;
        name1    = candidatesArray[1].name;
        address1 = candidatesArray[1].runningAddress;
        votes1   = candidatesArray[1].voteCount;
        name2    = candidatesArray[2].name;
        address2 = candidatesArray[2].runningAddress;
        votes2   = candidatesArray[2].voteCount;
        name3    = candidatesArray[3].name;
        address3 = candidatesArray[3].runningAddress;
        votes3   = candidatesArray[3].voteCount;
    }

    // returns vote count for a candidate
    function totalVotesFor(address candidateAddress) returns(uint votesForCandidate)
    {
        votesForCandidate = candidates[candidateAddress].voteCount;
    }

    // returns winning candidate address
    function winningCandidate() constant returns(address candidateAddress)
    {
        candidateAddress = winningCandidateAddress;
    }

    // returns winning candidate name
    function winnerName() constant returns (bytes32 winnerName)
    {
        winnerName = candidates[winningCandidateAddress].name;
    }
}

    /*********************************************************************************
     *
     * end of source
     *
     ********************************************************************************/
