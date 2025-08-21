// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./RandomNumberRetailerInterface.sol";

pragma solidity ^0.8.24;
/**
 * Cee-lo
 *
 * Non-neutral outcomes (38 unique sorted multisets):
 * - 1-2-3 (auto loss)                        -> 1 combo
 * - 4-5-6 (auto win)                         -> 1 combo
 * - Triples 111..666                         -> 6 combos
 * - Pair+odd (point = odd die)               -> 30 combos (for each point P, pick any pair value != P)
 *
 * We map a pseudo-random seed -> uniform index in [0..37] and deterministically construct the hand.
 *
 */
contract RNRCelo is ReentrancyGuard {
    uint256 public largestBetAllowedInWei;

    address public ownerAddress = 0x5F13FF49EF06a108c66D45C2b1F1211dBdE154CD;
    uint8 public minimumQueueLengthToExecuteTransactions = 1;
    uint8 public maximumLengthOfQueue = 20;

    enum HandResult{ PLAYER_WIN, BANKER_WIN, DRAW }
    event HandLog(address indexed userAddress, string handLog);

    struct CeloInput{
        address user;
        uint256 totalAmountPlayerSentInWei;
    }

    address private constant serverAddress = 0xD16512fdBb90096B1f1888Cae6152177065FdA62;

    // Points to the official RandomNumberRetailer contract.
    RandomNumberRetailerInterface public constant RANDOM_NUMBER_RETAILER = RandomNumberRetailerInterface(0xa15730e51c907AC047ecBF1f4c381602397c1398);
    uint8[3][38] public possibleRolls;

    mapping(bool => CeloInput[]) public celoHandQueue;

    function setMinimumQueueLengthToExecuteTransactions (uint8 newMinimumQueueLengthToExecuteTransactions) external onlyOwner{
        minimumQueueLengthToExecuteTransactions = newMinimumQueueLengthToExecuteTransactions;
    }

    function setMaximumLengthOfQueue (uint8 newSetMaximumLengthOfQueue) external onlyOwner{
        maximumLengthOfQueue = newSetMaximumLengthOfQueue;
    }

    function playCelo() external payable {

        uint256 priceOfARandomNumberInWei = RANDOM_NUMBER_RETAILER.priceOfARandomNumberInWei();
        uint256 amountToBetWithInWei = msg.value - priceOfARandomNumberInWei;

        require(
            amountToBetWithInWei > 0,
            "ERROR: You did not send enough ETH to pay for the RNR random number. Please send more ETH next time."
        );

        require(
            amountToBetWithInWei <= largestBetAllowedInWei,
            "ERROR: Your bet is too large. Please bet less ETH."
        );

        require(
            celoHandQueue[true].length < maximumLengthOfQueue,
            "Error: The play queue is already full. Please wait a minute and try again."
        );

        CeloInput memory input = CeloInput(msg.sender, msg.value);
        celoHandQueue[true].push(input);
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress, 
            "FAILURE: Only the owner can call this method."
        );

        _;
    }

    modifier onlyServer() {
        require(
            msg.sender == serverAddress, 
            "FAILURE: Only the server can call this method."
        );

        _;
    }
	
	constructor(){
        possibleRolls[0][0] = 1;
        possibleRolls[0][1] = 2;
        possibleRolls[0][2] = 3;

        possibleRolls[1][0] = 4;
        possibleRolls[1][1] = 5;
        possibleRolls[1][2] = 6;

        possibleRolls[2][0] = 1;
        possibleRolls[2][1] = 1;
        possibleRolls[2][2] = 1;

        possibleRolls[3][0] = 2;
        possibleRolls[3][1] = 2;
        possibleRolls[3][2] = 2;

        possibleRolls[4][0] = 3;
        possibleRolls[4][1] = 3;
        possibleRolls[4][2] = 3;

        possibleRolls[5][0] = 4;
        possibleRolls[5][1] = 4;
        possibleRolls[5][2] = 4;

        possibleRolls[6][0] = 5;
        possibleRolls[6][1] = 5;
        possibleRolls[6][2] = 5;

        possibleRolls[7][0] = 6;
        possibleRolls[7][1] = 6;
        possibleRolls[7][2] = 6;

        possibleRolls[8][0] = 1;
        possibleRolls[8][1] = 1;
        possibleRolls[8][2] = 2;

        possibleRolls[9][0] = 1;
        possibleRolls[9][1] = 1;
        possibleRolls[9][2] = 3;

        possibleRolls[10][0] = 1;
        possibleRolls[10][1] = 1;
        possibleRolls[10][2] = 4;

        possibleRolls[11][0] = 1;
        possibleRolls[11][1] = 1;
        possibleRolls[11][2] = 5;

        possibleRolls[12][0] = 1;
        possibleRolls[12][1] = 1;
        possibleRolls[12][2] = 6;

        possibleRolls[13][0] = 1;
        possibleRolls[13][1] = 2;
        possibleRolls[13][2] = 2;

        possibleRolls[14][0] = 2;
        possibleRolls[14][1] = 2;
        possibleRolls[14][2] = 3;

        possibleRolls[15][0] = 2;
        possibleRolls[15][1] = 2;
        possibleRolls[15][2] = 4;

        possibleRolls[16][0] = 2;
        possibleRolls[16][1] = 2;
        possibleRolls[16][2] = 5;

        possibleRolls[17][0] = 2;
        possibleRolls[17][1] = 2;
        possibleRolls[17][2] = 6;

        possibleRolls[18][0] = 1;
        possibleRolls[18][1] = 3;
        possibleRolls[18][2] = 3;

        possibleRolls[19][0] = 2;
        possibleRolls[19][1] = 3;
        possibleRolls[19][2] = 3;

        possibleRolls[20][0] = 3;
        possibleRolls[20][1] = 3;
        possibleRolls[20][2] = 4;

        possibleRolls[21][0] = 3;
        possibleRolls[21][1] = 3;
        possibleRolls[21][2] = 5;

        possibleRolls[22][0] = 3;
        possibleRolls[22][1] = 3;
        possibleRolls[22][2] = 6;

        possibleRolls[23][0] = 1;
        possibleRolls[23][1] = 4;
        possibleRolls[23][2] = 4;

        possibleRolls[24][0] = 2;
        possibleRolls[24][1] = 4;
        possibleRolls[24][2] = 4;

        possibleRolls[25][0] = 3;
        possibleRolls[25][1] = 4;
        possibleRolls[25][2] = 4;

        possibleRolls[26][0] = 4;
        possibleRolls[26][1] = 4;
        possibleRolls[26][2] = 5;

        possibleRolls[27][0] = 4;
        possibleRolls[27][1] = 4;
        possibleRolls[27][2] = 6;

        possibleRolls[28][0] = 1;
        possibleRolls[28][1] = 5;
        possibleRolls[28][2] = 5;

        possibleRolls[29][0] = 2;
        possibleRolls[29][1] = 5;
        possibleRolls[29][2] = 5;

        possibleRolls[30][0] = 3;
        possibleRolls[30][1] = 5;
        possibleRolls[30][2] = 5;

        possibleRolls[31][0] = 4;
        possibleRolls[31][1] = 5;
        possibleRolls[31][2] = 5;

        possibleRolls[32][0] = 5;
        possibleRolls[32][1] = 5;
        possibleRolls[32][2] = 6;

        possibleRolls[33][0] = 1;
        possibleRolls[33][1] = 6;
        possibleRolls[33][2] = 6;

        possibleRolls[34][0] = 2;
        possibleRolls[34][1] = 6;
        possibleRolls[34][2] = 6;

        possibleRolls[35][0] = 3;
        possibleRolls[35][1] = 6;
        possibleRolls[35][2] = 6;

        possibleRolls[36][0] = 4;
        possibleRolls[36][1] = 6;
        possibleRolls[36][2] = 6;

        possibleRolls[37][0] = 5;
        possibleRolls[37][1] = 6;
        possibleRolls[37][2] = 6;
	}

    function setlargestBetAllowedInWei(uint256 newLargestBetAllowedInWei) external onlyOwner{
        largestBetAllowedInWei = newLargestBetAllowedInWei;
    }

    function executeOneBatchOfTransactions(RandomNumberRetailerInterface.Proof [] memory proofs, RandomNumberRetailerInterface.RequestCommitment[] memory rcs) external onlyServer nonReentrant {
        CeloInput[] memory transactionsToExecute = celoHandQueue[true];

        require(
            transactionsToExecute.length >= minimumQueueLengthToExecuteTransactions,
            "Error: queue is too small to execute. Please wait until it is large enough."
        );

        require(
            proofs.length == transactionsToExecute.length, 
            "Error: Number of proofs does not match number of transactions to execute."
        );

        require(
            rcs.length == transactionsToExecute.length, 
            "Error: Number of request commitments does not match number of transactions to execute."
        );

        for (uint8 i = 0; i < transactionsToExecute.length; i++){
            CeloInput memory input = transactionsToExecute[i];
            playAsAggregator(input.totalAmountPlayerSentInWei, proofs[i], rcs[i], input.user);
        }

        delete celoHandQueue[true];
    }

    function playAsAggregator(
        uint256 totalAmountPlayerSentInWei,
        RandomNumberRetailerInterface.Proof memory proof, 
        RandomNumberRetailerInterface.RequestCommitment memory rc,
        address userAddress) private{

        uint256 randomNumbersAvailable = RANDOM_NUMBER_RETAILER.randomNumbersAvailable();
        uint256 priceOfARandomNumberInWei = RANDOM_NUMBER_RETAILER.priceOfARandomNumberInWei();

        require(
            randomNumbersAvailable > 0, 
            "ERROR: RNR is out of random numbers. Please try again later."
        );

        uint256 sizeOfBetInWei = totalAmountPlayerSentInWei - priceOfARandomNumberInWei;

        require(
            sizeOfBetInWei > 0,
            "ERROR: You did not send enough ETH to pay for the RNR random number. Please send more ETH next time."
        );

        require(
            sizeOfBetInWei <= largestBetAllowedInWei,
            "ERROR: Your bet is too large. Please bet less ETH."
        );

        uint256[] memory randomNumbersReturned = RANDOM_NUMBER_RETAILER.requestRandomNumbersSynchronousUsingVRFv2Seed{value: priceOfARandomNumberInWei}(1, proof, rc, false);
        uint256 randomNumberToUse = randomNumbersReturned[0];

        return playImpl(randomNumberToUse, sizeOfBetInWei, userAddress);
    }

    function convertGameToString(uint8[3] memory playerRoll, uint8[3] memory bankerRoll) private pure returns (string memory gameString){
        string memory playerRollString = string.concat(Strings.toString(playerRoll[0]), "-", Strings.toString(playerRoll[1]), "-", Strings.toString(playerRoll[2]));
        string memory bankerRollString = string.concat(Strings.toString(bankerRoll[0]), "-", Strings.toString(bankerRoll[1]), "-", Strings.toString(bankerRoll[2]));
        gameString = string.concat("Player rolled ", playerRollString, ". Banker rolled ", bankerRollString, ".");
    }

    /// Rank ordering:
    ///   300  : 4-5-6 (auto win)
    ///   200+X: triples (X = face 1..6)
    ///   100+P: point  (P = 1..6)
    ///   1    : 1-2-3 (auto loss)
    function rank(uint8[3] memory d) private pure returns (uint16) {
        // 1-2-3 auto loss
        if (d[0] == 1 && d[1] == 2 && d[2] == 3) return 1;

        // 4-5-6 auto win
        if (d[0] == 4 && d[1] == 5 && d[2] == 6) return 300;

        // Triples
        if (d[0] == d[1] && d[1] == d[2]) return 200 + d[0];

        // Pair -> point is the odd die
        if (d[0] == d[1]) return 100 + d[2];
        if (d[1] == d[2]) return 100 + d[0];

        // With our construction there are no neutrals
        return 0;
    }
    
    function playImpl(
        uint256 randomNumberToUse,
        uint256 sizeOfBetInWei,
        address userAddress
    ) private{

        uint256 playerCardIndex = randomNumberToUse % 38;
        uint8[3] memory playerRoll = possibleRolls[playerCardIndex];

        uint16 playerRollRank = rank(playerRoll);

        if(playerRollRank == 1){
            emit HandLog(userAddress, "Player auto loss (1-2-3)");
            return finishGame(HandResult.BANKER_WIN, sizeOfBetInWei, userAddress);
        }
        else if (playerRollRank == 300){
            emit HandLog(userAddress, "Player auto win (4-5-6)");
            return finishGame(HandResult.PLAYER_WIN, sizeOfBetInWei, userAddress);
        }

        uint256 bankerCardIndex = uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, randomNumberToUse))) % 38;
        uint8[3] memory bankerRoll = possibleRolls[bankerCardIndex];

        uint16 bankerRollRank = rank(bankerRoll);

        if(bankerRollRank == 1){
            emit HandLog(userAddress, "Banker auto loss (1-2-3)");
            return finishGame(HandResult.PLAYER_WIN, sizeOfBetInWei, userAddress);
        }
        else if (bankerRollRank == 300){
            emit HandLog(userAddress, "Banker auto win (4-5-6)");
            return finishGame(HandResult.BANKER_WIN, sizeOfBetInWei, userAddress);
        }

        string memory gameString = convertGameToString(playerRoll, bankerRoll);

        if(playerRollRank > bankerRollRank){
            emit HandLog(userAddress, string.concat("Player beats Banker. ", gameString));
            return finishGame(HandResult.PLAYER_WIN, sizeOfBetInWei, userAddress);
        }
        else if (playerRollRank < bankerRollRank){
            emit HandLog(userAddress, string.concat("Banker beats Player. ", gameString));
            return finishGame(HandResult.BANKER_WIN, sizeOfBetInWei, userAddress);
        }
        else{
            emit HandLog(userAddress, string.concat("Draw. ", gameString));
            return finishGame(HandResult.DRAW, sizeOfBetInWei, userAddress);
        }
    }

     function finishGame(
        HandResult result,
        uint256 sizeOfBetInWei,
        address userAddress
    ) private {
        uint256 payOutToUserInWei = 0;
        
        if (result == HandResult.PLAYER_WIN){            
            payOutToUserInWei = sizeOfBetInWei * 2;            
        }
        else if (result == HandResult.DRAW) {
            payOutToUserInWei = sizeOfBetInWei;
        }
        
        if(payOutToUserInWei != 0){
            require(
                payable(userAddress).send(payOutToUserInWei),
                "Error: Failed to withdraw ETH to the message sender."
            );
        }
    }

    function deposit() public payable {
        // This function can receive the native token
    }

    function withdrawETHToOwner(
        uint256 weiToWithdraw
    ) external nonReentrant onlyOwner {

        require(
            address(this).balance > weiToWithdraw,
            "FAILURE: There is not enough ETH in this contract to complete the withdrawal."
        );

        require(
            payable(ownerAddress).send(weiToWithdraw),
            "FAILURE: Failed to withdraw ETH to the owner."
        );
    }
}

contract Deployer {
   event ContractDeployed(address deployedContractAddress);

   constructor() {
      emit ContractDeployed(
        Create2.deploy(
            0, 
            "RNR Celo v1",
            type(RNRCelo).creationCode
        )
      );
   }
}
