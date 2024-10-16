// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowContract {
    address public buyer;
    address public seller;
    address public escrowAgent;
    uint public amount;
    bool public isBuyerApproved;
    bool public isSellerApproved;
    bool public isDisputed;

    enum State {
        AWAITING_PAYMENT, 
        AWAITING_DELIVERY, 
        COMPLETE, 
        REFUNDED
    }
    State public currentState;

    constructor(address _seller, address _escrowAgent) {
        buyer = msg.sender;
        seller = _seller;
        escrowAgent = _escrowAgent;
        currentState = State.AWAITING_PAYMENT;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }
    
    modifier onlyEscrowAgent() {
        require(msg.sender == escrowAgent, "Only escrow agent can call this function");
        _;
    }
    
    function depositFunds() public payable onlyBuyer {
        require(currentState == State.AWAITING_PAYMENT, "Invalid state for deposit");
        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;
    }
    
    function approveBySeller() public onlySeller {
        require(currentState == State.AWAITING_DELIVERY, "Invalid state for seller approval");
        isSellerApproved = true;
        if (isBuyerApproved) {
            releaseFunds();
        }
    }
    
    function approveByBuyer() public onlyBuyer {
        require(currentState == State.AWAITING_DELIVERY, "Invalid state for buyer approval");
        isBuyerApproved = true;
        if (isSellerApproved) {
            releaseFunds();
        }
    }
    
    function releaseFunds() private {
        require(isBuyerApproved && isSellerApproved, "Both parties must approve");
        payable(seller).transfer(amount);
        currentState = State.COMPLETE;
    }
    
    function raiseDipute() public {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise dispute");
        isDisputed = true;
    }
    
    function resolveDispute(bool _releaseToSeller) public onlyEscrowAgent {
        require(isDisputed, "No dispute to resolve");
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
        } else {
            payable(buyer).transfer(amount);
        }
        currentState = State.COMPLETE;
    }
    
    function refundBuyer() public onlyEscrowAgent {
        require(currentState == State.AWAITING_DELIVERY, "Invalid state for refund");
        payable(buyer).transfer(amount);
        currentState = State.REFUNDED;
    }
}