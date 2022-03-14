// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./HONEY.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract HONEYBANK is AccessControlEnumerable {

    HONEY public HONEY_TOKEN = HONEY(0xA1dcF3a4a6ED6011640da82911b495F415C77C50);

    uint256 public sellPrice = 2600;
    uint256 public buyPrice = 2000; 
    bool public open = true; 
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    receive() 
    external payable 
    {
    }

    function HONEYBalance() 
    public view returns (uint256)
    {
        return HONEY_TOKEN.balanceOf(address(this));
    }

    function MATICBalance() 
    public view returns (uint256)
    {
        return address(this).balance;
    }

    function sell(uint256 amount) 
    public payable
    {
        require((open), "Admin has disabled transactions.");
        HONEY_TOKEN.transferFrom(msg.sender, address(this), amount);
        uint256 maticPayout = amount / sellPrice;
        address payable seller = payable(msg.sender);
        seller.transfer(maticPayout);
    }

    function buy() 
    public payable
    {
        require((open), "Admin has disabled transactions.");
        uint256 purchase = msg.value * buyPrice;
        HONEY_TOKEN.transfer(msg.sender, purchase);
    }

    function changePrices(uint256 _buyPrice, uint256 _sellPrice) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        require(_sellPrice > _buyPrice, "Sell price must always be higher than buy price.");
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
    }

    function setOpen(bool _isOpen) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        open = _isOpen;
    }
}