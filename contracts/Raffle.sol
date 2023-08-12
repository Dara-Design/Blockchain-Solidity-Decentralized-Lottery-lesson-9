// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
//import "@hardhat/console.sol";

//to use and interact with VRF interfaces we need to import them
// moras da kucas u konzolu: npm add -–dev @chainlink/contracts

/*Errors*/
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();

//razlog zbog kojeg dajemo greskama imena ponaosob je taj sto u kompleksnijem kodu mozemo direkt da pronajdemo deo odakle je ta greska potekla

/**@title A sample Raffle Contract
 * @author Dara
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
//ugovor implementira interfejs, sto znaci da ima pristup njegovim poljima i metodama
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /*Type Declaration */
    enum RaffleState {
        OPEN, 
        CALCULATING

        //trabaju nam razlicita stanja za lutriju, zato stvaramo enum (koji kreiranja nova stanja za nas)
        //Ne zelimo da tokom kalkulacije pobednika dozvolimo novog korisniku da udje u igru
    }
/*State variables*/
//Chainlink VRF Variables
VRFCoordinatorV2Interface private immutable i_vrfCooodinator; //is the address of the contract that does the random number verification
uint64 private immutable i_subscriptionId;
bytes32 private immutable i_gasLane;
uint32 private immutable i_callbackGasLimit;
uint16 private constant REQUEST_CONFIRMATIONS =3;
uint32 private constant NUM_WORDS =1;

//Lottery Variables
uint256 private immutable i_interval;
uint256 private immutable i_entranceFee; // cena za ulazak u lutriju je 0.1 link token
uint256 private s_lastTimeStamp;
address private s_recentWinner;
address payable[] private s_players;
RaffleState private s_raffleState;

/*Events */

//Events can have indexed up to 3 parameters and non-index-parameters, 
//Indexed parameters = topics, they are much easier to search for

event RequestedRaffleWinner(uint256 indexed requestId);
event RaffleEnter(address indexed player);
event WinnerPicked(address indexed player);

/*Functions*/ 
constructor (
    address vrfCoordinatorV2,
    uint64 subcsriptionId,
    bytes32 gasLane,//keyHash
    uint256 interval,
    uint256 entranceFee,
    uint32 callbackGasLimit

)VRFConsumerBaseV2(vrfCoordinatorV2){
    i_vrfCooodinator= VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane =gasLane;
    i_interval =interval;
    i_subscriptionId =subcsriptionId;
    i_entranceFee =entranceFee;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_callbackGasLimit = callbackGasLimit;

}

function enterRaffle() public payable {
     // require(msg.value >= i_entranceFee, "Not enough value sent");
    // require(s_raffleState == RaffleState.OPEN, "Raffle is not open");

    if(msg.value < i_entranceFee){
        revert Raffle__SendMoreToEnterRaffle();

    }

    if(s_raffleState != RaffleState.OPEN){
         
         revert Raffle__RaffleNotOpen();

    }

    s_players.push(payable(msg.sender)); //typecasting msg.sender as payable address
    // Emit an event when we update a dynamic array or mapping
    // Named events with the function name reversed
     emit  RaffleEnter(msg.sender);
}

 /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription is funded with LINK.
     */
     //za ovu funkciju se ne trosi gas, jer se provera obavlja van lanca
     function checkUpkeep(bytes memory /*checkData*/) public view override returns(bool upkeepNeeded, bytes memory/*performData*/){  //kada imas bytes kao vrstu ulaznih podataka mozes sve da ubacis kao ulazni parametar- cak i funkcije
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp)> i_interval); //ukupno vreme - minus poslednje izmereno vreme( tj. njihova razlika) mora biti veca  od zadatog intervala
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return(upkeepNeeded, "0x0"); //salje  empty bites, jer nije nam bitan taj podatak, a mora da postoji taj parametar

     }
     //ukoliko su svi uslovi ispunjeni, chailnlink keeper automatski trigeruje pozivanje funkcije performUpkeep
     
      /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /*performData */)external override{
        (bool upkeepNeeded, ) = checkUpkeep("");
        //require(upkeepNeeded, "Upkeep not needed");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );

        }

    s_raffleState = RaffleState.CALCULATING;

    uint256 requestId = i_vrfCooodinator.requestRandomWords(i_gasLane,i_subscriptionId,REQUEST_CONFIRMATIONS,i_callbackGasLimit,NUM_WORDS);
    //ova proces  je dvokomponentan i dobro je sto je tako- ne zelimo da neko silom izaziva pozivanje funkcija i samoproglasi se za dobitnika lutrije
    //prvo dobijemo random brojeve a onda 'uradimo' nesto sa njima
    emit RequestedRaffleWinner(requestId);
    }

      /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */

    function fulfillRandomWords(uint256, /* requestId*/ uint256[] memory randomWords) internal override {
        // s_players size 10
        // randomNumber 202
        // 202 % 10 ? what's doesn't divide evenly into 202?
        // 20 * 10 = 200
        // 2
        // 202 % 10 = 2

        //koristimo modul da dobijemo broj od 0-9 za pronalazak indexa igraca
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0); //resetujemo slot sa adresama
        s_raffleState = RaffleState.OPEN; // RAFFLE stanje je opet otvoreno
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value : address(this).balance}("");
          // require(success, "Transfer failed");
        
        if(!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }


   /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

}




