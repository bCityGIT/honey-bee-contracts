// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./HONEY.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BeeCityv1 is ERC721PresetMinterPauserAutoId {

    HONEY public HONEY_TOKEN = HONEY(0xA1dcF3a4a6ED6011640da82911b495F415C77C50);

    using Strings for uint256;
   
    uint16 public maxSupply = 9999;
    uint256 public price = 255000000000000000000; // start at 255MATIC
    address payable treasury = payable(0x8D2c8eddd8136f91450E5462Db12E9E166DEFa97); // bee city treasury
    address payable bank = payable(0xF66fc1861CaE4275Af265C9A5965F57A942d99D0); // bee city bank

    string URIRoot = "https://gateway.pinata.cloud/ipfs/QmZQZTxVvz1BNQJWodVUVceNSsLTtWu5qAfrMJzRSoNfPX/";
    struct Bee {
        uint shape;
        uint256 honeyPerDay;
        uint256 honeyCollectedLast;
        uint256 tokenId;
    }

    mapping(uint256 => Bee) public bees;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Bee City", "BEECITY", URIRoot) {
    }

    function updateBank(address payable _b) 
    public 
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        bank = _b;
    }

    function updateHoney(address _e) 
    public 
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        HONEY_TOKEN = HONEY(_e);
    }

    function collectHoney(uint256 id)
    public 
    {   
        Bee memory bee = bees[id];
        uint32 dayInSeconds = 86400;
        require(ownerOf(id) == msg.sender, "only owner can collect honey.");
        require(block.timestamp > (bee.honeyCollectedLast + dayInSeconds), "honey already collected.");
        HONEY_TOKEN.mint(msg.sender, bee.honeyPerDay);
        bees[id].honeyCollectedLast = block.timestamp;
    }

    function collectAll()
    public 
    {
        uint256 honey = 0;
        for (uint8 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 index = tokenOfOwnerByIndex(msg.sender, i);
            Bee memory bee = bees[index];
            uint32 dayInSeconds = 86400;
            if (block.timestamp > (bee.honeyCollectedLast + dayInSeconds)) {
                honey += bee.honeyPerDay;
                bees[index].honeyCollectedLast = block.timestamp;
            }
        }
        HONEY_TOKEN.mint(msg.sender, honey);
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }
    
    function updateURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function buy(uint8 quantity) payable external {
        require(quantity > 0, "Quantity must be more than 1.");
        require(quantity <= 30, "Quantity must be less than 30.");
        require(msg.value >= price * quantity, "Not enough MATIC.");
        mintNFT(quantity);
        payAccounts();
    }
    
    function mintNFT(uint16 amount)
    private
    {
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require((totalMinted + amount) <= maxSupply, "Sold out.");
        
        for (uint i = 0; i < amount; i++) { 
            uint256 currentID = _tokenIds.current();
            uint shape = getBeeShape(currentID);
            _mint(msg.sender, currentID);
            createBee(currentID, shape);
            _tokenIds.increment();
        }
    }

    function migrateNFT(uint shape, address _ownerAddr) public {
        require((totalSupply() + 1) <= maxSupply, "Sold out.");
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        uint256 currentID = _tokenIds.current();
        _mint(_ownerAddr, currentID);
        createBee(currentID, shape);
        _tokenIds.increment();
    }

    function createBee(uint256 id, uint shape) 
    private
    {
        uint256 honeyPerDay = getHoneyPerDay(shape);
        uint32 dayInSeconds = 86400;
        bees[id] = Bee(
            shape,
            honeyPerDay,
            block.timestamp - dayInSeconds,
            id
        );
    }

    function getHoneyPerDay(uint shape) 
    private
    pure
    returns (uint256)
    {
        if (shape == 0) {
            return 70000000000000000000; // Queen
        }
        else if (shape == 1) {
            return 20000000000000000000; // Karen
        }
        else if (shape == 2) {
            return 20000000000000000000; // Buzzy
        }
        else if (shape == 3) {
            return 20000000000000000000; // Tobi
        }
        else if (shape == 4) {
            return 12000000000000000000; // Demolition
        }
        else if (shape == 5) {
            return 10000000000000000000; // Excavator
        }
        else {
            return 10000000000000000000; // Miner
        }
    }

    function getBeeShape(uint256 i) 
    private
    pure
    returns (uint)
    {
        uint256 j = i;
        if (j % 100 == 0) {
            return 0; // Queen
        }
        else if (j % 13 == 0) {
            return 1; // Karen
        }
        else if (j % 12 == 0) {
            return 2; // Buzzy
        }
        else if (j % 11 == 0) {
            return 3; // Tobi
        }
        else if (j % 3 == 0) {
            return 4; // Demolition
        }
        else if (j % 2 == 0) {
            return 5; // Excavator
        }
        else {
            return 6; // Miner
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory shape = Strings.toString(bees[tokenId].shape);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(URIRoot, shape, ".json")) : "";
    }
    
    function payAccounts() public payable {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 devCut = balance * 30 / 100;
            uint256 bankCut = balance * 70 / 100;
            treasury.transfer(devCut);
            bank.transfer(bankCut);
        }
    }
}