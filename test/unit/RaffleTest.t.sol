// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-evm/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffleContract;
    HelperConfig public helperConfigContract;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    event RaffleEntered(address indexed player); // to track the players who entered
    event WinnerPicked(address indexed winner); // to track the winner picked

    function setUp() external {
        DeployRaffle deployRaffleContract = new DeployRaffle();
        (raffleContract, helperConfigContract) = deployRaffleContract.deployContract();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfigContract.getConfigByChainId(block.chainid);

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffleContract.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testUserFailsToEnterRaffle() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughEthEntered.selector);
        vm.prank(PLAYER);
        raffleContract.enterRaffle();
    }

    function testUserEntersRafflePlayersArray() public {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        assertEq(raffleContract.getUserAddress(0), PLAYER);
        assertEq(raffleContract.getNumberOfPlayers(), 1);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffleContract));
        emit RaffleEntered(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
    }

    function testCantEnterRaffleWhileItisInCalculatingState() public {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffleContract.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
    }

    // ------------------------------  CHECK UPKEEP TESTS ---------------------------------//

    function testCheckUpKeepReturnsFalseIfNotEnoughEth() public {
        (bool upkeepNeeded,) = raffleContract.checkUpKeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfNotEnoughPlayers() public {
        (bool upkeepNeeded,) = raffleContract.checkUpKeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffleContract.performUpkeep("");

        (bool upkeepNeeded,) = raffleContract.checkUpKeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllConditionsAreMet() public {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffleContract.checkUpKeep("");
        assert(upkeepNeeded);
    }

    // ------------------------------  PERFORMUPKEEP TESTS ---------------------------------//

    function testPerformUpKeepRunsOnlyWhenCkeckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffleContract.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = raffleContract.getRaffleState();

        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee;
        numPlayers += 1;

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpKeepNeededError.selector, currentBalance, numPlayers, raffleState)
        );
        raffleContract.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffleContract.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsEvent() public raffleEntered {
        vm.recordLogs();
        raffleContract.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // requestId is indexed and stored in topics array

        Raffle.RaffleState raffleState = raffleContract.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // calculating state
    }

    // ------------------------------  FULLFILLRANDOMWORDS TESTS ---------------------------------//

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomReqId)
        public
        raffleEntered
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomReqId, address(raffleContract));
    }

    function testFullFillRandomWordsPicksWinnersResetsAndSendsMoney() public raffleEntered skipFork {
        uint256 additionalNewPlayers = 3; //total 4
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i < additionalNewPlayers + startingIndex; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffleContract.enterRaffle{value: entranceFee}();
        }
        console.log("Raffle balance ", address(raffleContract).balance);

        uint256 startingTimeStamp = raffleContract.getLastTimeStamp();
        console.log("Starting timestamp ", startingTimeStamp);
        uint256 winnerStartingBalance = expectedWinner.balance;
        console.log("Winner starting balance ", winnerStartingBalance);

        vm.recordLogs();
        raffleContract.performUpkeep("");
        Vm.Log[] memory enteries = vm.getRecordedLogs();
        bytes32 requestId = enteries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffleContract));
        address recentWinner = raffleContract.getRecentWinner();
        Raffle.RaffleState raffleState = raffleContract.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        console.log("Winner ending balance ", winnerBalance);
        uint256 endingTimeStamp = raffleContract.getLastTimeStamp();
        console.log("Ending timestamp ", endingTimeStamp);
        uint256 prize = entranceFee * (additionalNewPlayers + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0); // open state
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}

