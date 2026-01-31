// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Web3PayRequest {

    enum RequestState {
        Pending,
        Paid,
        Cancelled,
        Expired
    }

    struct Request {
        address payer;
        address payee;
        address token;
        uint256 amount;
        uint256 createdAt;
        uint256 expiresAt;
        RequestState state;
    }

    Request[] public requests;

    event RequestCreated(
        uint256 indexed requestId,
        address indexed payer,
        address indexed payee,
        address token,
        uint256 amount,
        uint256 expiresAt,
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

    event RequestExpired(
        uint256 indexed requestId,
        uint256 timestamp
    );

    uint256 public constant DEFAULT_DURATION = 120;

    modifier validRequest(uint256 requestId) {
        require(requestId < requests.length, "Invalid request");
        _;
    }

    modifier inState(uint256 requestId, RequestState _state) {
        require(requests[requestId].state == _state, "Invalid state");
        _;
    }

    modifier notPaid(uint256 requestId) {
        require(requests[requestId].state != RequestState.Paid, "Already paid");
        _;
    }

    modifier onlyPayee(uint256 requestId) {
        require(msg.sender == requests[requestId].payee, "Not payee");
        _;
    }

    modifier notExpired(uint256 requestId) {
        require(block.timestamp < requests[requestId].expiresAt, "Request expired");
        _;
    }

    // function to create a request 
    function createRequest(address payer, address token, uint256 amount, uint256 duration) external returns(uint256) {
        require(amount > 0, "Amount must be greater than 0");
        require(token != address(0), "Invalid token address");
        
        if (duration == 0) {
            duration = DEFAULT_DURATION;
        }

        uint256 expiresAt = block.timestamp + duration;

        requests.push(
            Request({
                payer: payer,
                payee: msg.sender,
                token: token,
                amount: amount,
                createdAt: block.timestamp,
                expiresAt: expiresAt,
                state: RequestState.Pending
            })
        );

        emit RequestCreated(requests.length - 1, payer, msg.sender, token, amount, expiresAt, block.timestamp);

        return requests.length - 1;
    }

    function pay(uint256 requestId) external validRequest(requestId) notPaid(requestId) {
        Request storage r = requests[requestId];

        require(requests[requestId].state == RequestState.Pending, "Request is not payable");

        if (r.payer != address(0)) {
            require(msg.sender == r.payer, "Not authorized payer");   
        }

        IERC20(r.token).transferFrom(msg.sender, r.payee, r.amount);

        r.state = RequestState.Paid;

        emit RequestPaid(requestId, r.payer, r.payee, r.token, r.amount, block.timestamp);
    }

    function cancelRequest(uint256 requestId) external validRequest(requestId) notPaid(requestId) onlyPayee(requestId) {
        requests[requestId].state = RequestState.Cancelled;

        emit RequestCancelled(requestId, msg.sender, block.timestamp);
    }

    function expireRequest(uint256 requestId) external validRequest(requestId) notPaid(requestId) notExpired(requestId) {
        requests[requestId].state = RequestState.Expired;

        emit RequestExpired(requestId, block.timestamp);
    }

    function canPay(uint256 requestId) external view validRequest(requestId) returns (bool) {
        Request storage r = requests[requestId];
        return r.state == RequestState.Pending && r.expiresAt > block.timestamp;
    }

    function fetchRequests(address payee) external view returns (Request[] memory) {
        uint256 count= 0;
        for (uint256 i= 0; i < requests.length; i++) {
            if (requests[i].payee == payee) {
                count++;
            }
        }

        Request[] memory result= new Request[](count);

        uint256 index= 0;
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].payee == payee) {
                result[index] = requests[i];
                index++;
            }
        }
    
        return result;
    }
}