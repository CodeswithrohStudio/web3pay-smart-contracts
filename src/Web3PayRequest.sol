// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Web3PayRequest {
    struct Request {
        address payer;
        address payee;
        address token;
        uint256 amount;
        bool paid;
    }

    Request[] public requests;

    event RequestCreated(
        uint256 indexed requestId,
        address indexed payer,
        address indexed payee,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event RequestPaid(
        uint256 indexed requestId,
        address indexed payer,
        address indexed payee,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event RequestCancelled(
        uint256 indexed requestId,
        address indexed payee,
        uint256 timestamp
    );

    modifier validRequest(uint256 requestId) {
        require(requestId < requests.length, "Request is not valid");
        _;
    }

    modifier notPaid(uint256 requestId) {
        require(!requests[requestId].paid, "Already paid");
        _;
    }

    modifier onlyPayee(uint256 requestId) {
        require(msg.sender == requests[requestId].payee, "Not the payee");
        _;
    }

    // function to create a request 
    function createRequest(address payer, address token, uint256 amount) external returns(uint256) {
        requests.push(
            Request({
                payer: payer,
                payee: msg.sender,
                token: token,
                amount: amount,
                paid: false
            })
        );

        emit RequestCreated(requests.length - 1, payer, msg.sender, token, amount, block.timestamp);

        return requests.length - 1;
    }

    function pay(uint256 requestId) external validRequest(requestId) notPaid(requestId) {
        Request storage r = requests[requestId];

        require(!r.paid, "Already paid");

        if (r.payer != address(0)) {
            require(msg.sender == r.payer, "Not authorized payer");   
        }

        IERC20(r.token).transferFrom(msg.sender, r.payee, r.amount);

        r.paid = true;

        emit RequestPaid(requestId, r.payer, r.payee, r.token, r.amount, block.timestamp);
    }

    function cancelRequest(uint256 requestId) external validRequest(requestId) notPaid(requestId) onlyPayee(requestId) {
        requests[requestId].paid = true;

        emit RequestCancelled(requestId, msg.sender, block.timestamp);
    }
}
