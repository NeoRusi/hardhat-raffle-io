//Raffle
//Enter by paying some amount
//pick a random winner verifiyably random
///winner to be selected every X minutes -> completely automated
//Chainlink oracle -> Randomness outside the blockchain, Automated Execution
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__upKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**@title A sammple Raffle contract
 * @author Ruslan Kuliev
 * @notice This contrat is for creating an untamperable decentralized smart contract lottery
 * @dev this implemets CHAINLINK VRF2 and CHAINLINK keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /*Types declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /*State Variables*/
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGacLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private i_interval;
    //Lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState; //to pending , open, closed, calculation
    uint256 private s_lastTimeStamp;
    /*Events*/
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /**Functions */
    constructor(
        address vrfCoordinatorV2, // contract
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGacLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGacLimit = callBackGacLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        //Emit an event when we update a dinamic array or mapping
        //named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     *@dev This is the function that the chainlink node calls to
     *They look for the `upkeepNeeded` to return true
     *The following should be true in order to return truth
     1. Our time interval should have passed
     2. The lottery should have at least one player
     3.Our subscription is funded with LINK
     4. The lottery should be in an "open" state

     */
    function checkUpkeep(
        bytes memory /* checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /**peformData */
        )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        //(block.timestamp - last block.timestamp) > interval
    }

    function performUpkeep(
        bytes calldata /** */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        //Request hte random number
        if (!upkeepNeeded) {
            revert Raffle__upKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        //Once we get it do somethig with it
        //2 transaction proccess
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gasLane
            i_subscriptionId, //
            REQUEST_CONFIRMATIONS, // the amount of blocks to be hashed
            i_callBackGacLimit, // the maximum amoint of gas to be usedx
            NUM_WORDS // the amount of random words that we need
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        //s_player = 10
        //randomNumber 202
        //202 % 10 = 2
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        //require success gas efficient way
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /*View/Pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberWords() public view returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public view returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
