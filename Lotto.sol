// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract EthLotto {
    address private owner = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    event Received(address, uint);
    event Winner(address, uint payout, uint odds);
    event WinnerPaid(address, uint payout, uint odds);
    event SponsorPaid(address, uint payout, uint odds);
    event SponsorNeeded(uint odds);
    event SponsorAdded(uint odds, address sponsor);

    struct Lotto {
        uint odds;
        uint jackpot;
        uint numberToGuess;
        address sponsor;
    }

    mapping (uint => Lotto) public currentLottos;

    constructor() {

    }


    function balance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function jackpotAmount(uint _odds) public view returns(uint) {
        return currentLottos[_odds].jackpot;
    }

    function newLotto(uint _odds) public {
        require(_odds > 1, "Must select greater than 1:1 odds");
        require(currentLottos[_odds].odds == 0, "Lotto Already Exists!");

        currentLottos[_odds].odds = _odds;
        currentLottos[_odds].numberToGuess = generateNumber(_odds);

        emit SponsorNeeded(_odds);
    }

    function sponsorLotto(uint _odds) public {
        require(currentLottos[_odds].sponsor == address(0x0), "Lotto is already sponsored");
        currentLottos[_odds].sponsor = msg.sender;

        emit SponsorAdded(_odds, msg.sender);
    }

    function generateNumber(uint _odds) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % _odds;
    }

    function paySponsor(uint _odds, uint _jackpot) internal {
        uint _payout = ((_jackpot * 5) / 100) * 1 wei;

        (bool success,  ) = payable(currentLottos[_odds].sponsor).call{ value: _payout }("");
        require(success, "Failed to transfer the funds to Sponsor, aborting.");

        emit SponsorPaid(msg.sender, _payout, _odds);
    }

    function payWinner(uint _odds, uint _jackpot) internal {
        uint _payout = ((_jackpot * 95) / 100) * 1 wei;

        (bool success,  ) = payable(msg.sender).call{ value: _payout }("");
        require(success, "Failed to transfer the funds to Winner, aborting.");

        emit WinnerPaid(msg.sender, _payout, _odds);
    }

    function guessNumber(uint _odds, uint _guess) public payable {
        require(msg.value > 1 ether, "You must bet more than 1 eth in order to play");
        require(currentLottos[_odds].odds != 0, "Lotto Doesn't Exists!");
        require(currentLottos[_odds].sponsor != address(0x0), "Lotto Doesn't Have a Sponsor!");

        collectFee();
        currentLottos[_odds].jackpot += uint256(msg.value - 1 ether);

        if (_guess == currentLottos[_odds].numberToGuess) {
            uint _jackpot = currentLottos[_odds].jackpot;

            paySponsor(_odds, _jackpot);
            payWinner(_odds, _jackpot);

            emit Winner(msg.sender, currentLottos[_odds].jackpot, _odds);

            delete currentLottos[_odds];
            newLotto(_odds);
        }
    }

    function collectFee() internal {
        (bool success, ) = payable(owner).call{ value: 1 ether }("");
        require(success, "Failed to transfer the funds, aborting.");

        emit Received(msg.sender, 1 ether);
    }

}