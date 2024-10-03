// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoomiesApp {
    struct Task {
        address creator;
        string description;
        uint256 reward; // cryptocurrency reward
        address assignee;
        bool isCompleted;
    }

    struct Expense {
        address payer;
        string description;
        uint256 amount;
        address[] participants;
        bool isPaid;
    }

    struct UserProfile {
        string name;
        string email;
        bool isVerified;
    }

    mapping(address => UserProfile) public profiles;  // Map user addresses to profiles
    mapping(address => uint256) public rentBalances;  // Track users' rent balances
    Task[] public tasks;                             // Array of all tasks in the marketplace
    Expense[] public expenses;                       // Array of all shared expenses

    event TaskCreated(uint256 taskId, address creator, string description, uint256 reward);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompleted(uint256 taskId);
    event ExpenseAdded(uint256 expenseId, address payer, string description, uint256 amount, address[] participants);
    event ExpenseSettled(uint256 expenseId);
    event RentPaid(address payer, uint256 amount);
    event UserProfileUpdated(address user, string name, string email, bool isVerified);

    // Create a new task
    function createTask(string memory description, uint256 reward) public {
        tasks.push(Task({
            creator: msg.sender,
            description: description,
            reward: reward,
            assignee: address(0),
            isCompleted: false
        }));
        emit TaskCreated(tasks.length - 1, msg.sender, description, reward);
    }

    // Assign a task to yourself
    function assignTask(uint256 taskId) public {
        require(taskId < tasks.length, "Task does not exist");
        Task storage task = tasks[taskId];
        require(task.assignee == address(0), "Task already assigned");
        task.assignee = msg.sender;
        emit TaskAssigned(taskId, msg.sender);
    }

    // Complete a task and release the reward
    function completeTask(uint256 taskId) public {
        require(taskId < tasks.length, "Task does not exist");
        Task storage task = tasks[taskId];
        require(msg.sender == task.assignee, "Only assignee can complete task");
        require(!task.isCompleted, "Task already completed");
        task.isCompleted = true;
        payable(task.assignee).transfer(task.reward);  // Transfer reward to assignee
        emit TaskCompleted(taskId);
    }

    // Pay rent
    function payRent() public payable {
        require(msg.value > 0, "Rent payment must be greater than zero");
        rentBalances[msg.sender] += msg.value;
        emit RentPaid(msg.sender, msg.value);
    }

    // Add a shared expense
    function addExpense(string memory description, uint256 amount, address[] memory participants) public {
        expenses.push(Expense({
            payer: msg.sender,
            description: description,
            amount: amount,
            participants: participants,
            isPaid: false
        }));
        emit ExpenseAdded(expenses.length - 1, msg.sender, description, amount, participants);
    }

    // Settle an expense and distribute the cost among participants
    function settleExpense(uint256 expenseId) public {
        require(expenseId < expenses.length, "Expense does not exist");
        Expense storage expense = expenses[expenseId];
        require(!expense.isPaid, "Expense already settled");
        
        uint256 splitAmount = expense.amount / expense.participants.length;
        for (uint256 i = 0; i < expense.participants.length; i++) {
            rentBalances[expense.participants[i]] -= splitAmount;
        }
        
        expense.isPaid = true;
        emit ExpenseSettled(expenseId);
    }

    // Update or create a user profile
    function updateProfile(string memory name, string memory email, bool isVerified) public {
        profiles[msg.sender] = UserProfile(name, email, isVerified);
        emit UserProfileUpdated(msg.sender, name, email, isVerified);
    }

    // Fallback function to accept payments for the reward pool or rent pool
    receive() external payable {}

    // View a user's profile
    function getUserProfile(address user) public view returns (string memory name, string memory email, bool isVerified) {
        UserProfile memory profile = profiles[user];
        return (profile.name, profile.email, profile.isVerified);
    }
}
