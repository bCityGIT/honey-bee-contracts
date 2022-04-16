// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./HNYb.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract HONEYBANK is AccessControlEnumerable {

    // HNYb public HNYb_TOKEN = HNYb(0x0981d7Ef2f928a6c72FB1E63560CD986b98C54f7);
    HNYb public HNYb_TOKEN = HNYb(0x5C0004Dab31AE74017C46c9F14cD3dd657979FBe);

    // uint256 public sellPrice = 2600;
    // uint256 public buyPrice = 2000; 
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

    function HNYbBalance() 
    public view returns (uint256)
    {
        return HNYb_TOKEN.balanceOf(address(this));
    }

    function HNYbBalanceOfUser() 
    public view returns (uint256)
    {
        return HNYb_TOKEN.balanceOf(msg.sender);
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
        HNYb_TOKEN.transferFrom(msg.sender, address(this), amount);
        uint256 maticPayout = amount / sellPrice;
        address payable seller = payable(msg.sender);
        seller.transfer(maticPayout);
    }

    function buy() 
    public payable
    {
        require((open), "Admin has disabled transactions.");
        uint256 purchase = msg.value * buyPrice;
        HNYb_TOKEN.transfer(msg.sender, purchase);
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