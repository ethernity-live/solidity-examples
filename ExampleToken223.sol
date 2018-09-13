pragma solidity ^0.4.13;

    /*********************************************************************************
     *********************************************************************************
     *
     * ERC223Basic contract
     *
     *********************************************************************************
     *********************************************************************************/

contract ERC223Basic {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

    /*********************************************************************************
     *********************************************************************************
     *
     * SilverbackToken contract - 223 compliant
     *
     *********************************************************************************
     *********************************************************************************/

contract ExampleToken223 is ERC223Basic {

    uint    public totalSupply;
    address public crowdsaleCreator;

    // This creates an array with all balances
    mapping (address => uint256) public tokenBalanceOf;

    /*********************************************************************************
     *
     * Events
     *
     *********************************************************************************/

    event TransferD(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed from, address indexed to, uint value);

    /*********************************************************************************
     *
     * Constructor - 
     *
     *********************************************************************************/

    function ExampleToken223(uint256 initialSupply) {
        crowdsaleCreator = tx.origin;
        // Give the creator all initial tokens
        tokenBalanceOf[crowdsaleCreator] = initialSupply;
    }

    /*********************************************************************************
     *
     * Token functions
     *
     *********************************************************************************/

    function balanceOf(address who) constant returns (uint) {
        return tokenBalanceOf[who];
    }

    function transfer(address _to, uint256 _value) {
        // Transfer coins
        if (tokenBalanceOf[crowdsaleCreator] < _value) throw;          // Check if creator has enough balance
        if (tokenBalanceOf[_to] + _value < tokenBalanceOf[_to]) throw; // Check for overflows
        tokenBalanceOf[crowdsaleCreator] -= _value;                    // Subtract from the creator
        tokenBalanceOf[_to] += _value;                                 // Add the same to the recipient
        Transfer(crowdsaleCreator, _to, _value);
    }

    function transfer(address _to, uint _value, bytes _data) {
        TransferD(crowdsaleCreator, _to, _value, _data);
        transfer(_to, _value);
    }

}


    /*********************************************************************************
     *********************************************************************************
     *
     * Silverback contract
     *
     *********************************************************************************
     *********************************************************************************/

contract Silverback {

    /*********************************************************************************
     *
     * Data
     *
     *********************************************************************************/

    address            public beneficiary;
    uint               public fundingGoal;
    uint               public amountRaised;
    uint               public deadline;
    uint               public tokenPrice;
    ExampleToken223 public tokenReward;   

    // all funders
    Funder[] public funders;

    // data structure to hold information about funders (campaign contributors)
    struct Funder {
        address funderAddress;
        uint    funderBalanceEther;
    }


    /*********************************************************************************
     *
     * Events
     *
     *********************************************************************************/

    event FundTransfer(address backer, uint amount, bool isContribution);

    event TokenTransfer(address backer, uint amount);


    /*********************************************************************************
     *
     * Validations
     *
     *********************************************************************************/

    modifier afterDeadline() { if (now >= deadline) _; }


    /*********************************************************************************
     *
     * Constructor
     *
     *********************************************************************************/

    function Silverback(address _beneficiary, uint _fundingGoal, uint _duration, uint _tokenPrice, ExampleToken223 _reward) {
        beneficiary = _beneficiary;
        fundingGoal = _fundingGoal;
        deadline    = now + _duration * 60 minutes;
        tokenPrice  = _tokenPrice;
        tokenReward = ExampleToken223(_reward);
    }   


    /*********************************************************************************
     *
     * Payable function
     * (this function without name is the default function that is called whenever anyone sends funds to a contract)
     *
     *********************************************************************************/

    function () payable {
        // get msg/transaction values
        address funderAddress      = msg.sender;
        uint    funderBalanceEther = msg.value;
        // record balances
        funders[funders.length++] = Funder(funderAddress, funderBalanceEther);
        amountRaised += funderBalanceEther;
        uint256 tokensToTransfer = funderBalanceEther / tokenPrice;
        tokenReward.transfer(funderAddress, tokensToTransfer);
        // record events
        FundTransfer(funderAddress, funderBalanceEther, true);
        TokenTransfer(funderAddress, tokensToTransfer);
    }


    /*********************************************************************************
     *
     * Crowsale functions 
     *
     *********************************************************************************/

    function getBalances() constant returns(address address0, uint amount0,
                                            address address1, uint amount1,
                                            address address2, uint amount2,
                                            address address3, uint amount3) {
        address0 = funders[0].funderAddress;
        amount0  = funders[0].funderBalanceEther;
        address1 = funders[1].funderAddress;
        amount1  = funders[1].funderBalanceEther;
        address2 = funders[2].funderAddress;
        amount2  = funders[2].funderBalanceEther;
        address3 = funders[3].funderAddress;
        amount3  = funders[3].funderBalanceEther;
    }

    function getStatus() constant returns(address            beneficiaryR,
                                          uint               fundingGoalR,
                                          uint               amountRaisedR,
                                          uint               deadlineR,
                                          uint               tokenPriceR,
                                          ExampleToken223 tokenRewardR) {
        beneficiaryR  = beneficiary;
        fundingGoalR  = fundingGoal;
        amountRaisedR = amountRaised;
        deadlineR     = deadline;
        tokenPriceR   = tokenPrice;
        tokenRewardR  = tokenReward;
    }

    function checkGoalReached() afterDeadline {
        //checks if the goal or time limit has been reached and ends the campaign)
        if (amountRaised >= fundingGoal){
            beneficiary.send(amountRaised);
            FundTransfer(beneficiary, amountRaised, false);
        } else {
            FundTransfer(0, 11, false);
            for (uint i = 0; i < funders.length; ++i) {
              funders[i].funderAddress.send(funders[i].funderBalanceEther);
              FundTransfer(funders[i].funderAddress, funders[i].funderBalanceEther, false);
            }               
        }
        selfdestruct(beneficiary);
    }
}

   /*********************************************************************************
     *
     * End of source
     *
     *********************************************************************************/
