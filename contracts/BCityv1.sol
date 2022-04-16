// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./HNYb.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BCityv1 is ERC721PresetMinterPauserAutoId {

    // HNYb public HNYb_TOKEN = HNYb(0x0981d7Ef2f928a6c72FB1E63560CD986b98C54f7);
    // HNYb public HNYb_TOKEN = HNYb(0xE0907b6fba0E6dDBb6aE1b1D447697C55AA7Ac7E); //main
    HNYb public HNYb_TOKEN = HNYb(0x5C0004Dab31AE74017C46c9F14cD3dd657979FBe);

    using Strings for uint256;
   
    uint16 public maxSupply = 9999;
    uint8 public treasuryPercent = 30;
    uint8 public bankPercent = 70;
    uint8 public maxMintAmount = 30;
    // uint256 public price = 255000000000000000000; // start at 255MATIC
    uint256 public price = 10000000000000000; // start at 0.1MATIC
    address payable treasury = payable(0xaD4b5983a5bbcc29E6F0860D8f126B68A3850984); // bCity treasury
    address payable bank = payable(0x83401FaBb9a7CB39f89a26a013f51B197D72F318); // bCity bank

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
    uint256[100] private shapeIds;
    uint256 private remainShapeCounts = 100;

    function shuffleShapeIds() 
    private 
    {
        remainShapeCounts = 100;

        for (uint256 i = 0; i < 100; i++) {
            shapeIds[i] = i + 1;
        }
    }
    
    constructor() ERC721PresetMinterPauserAutoId("bCity", "BCITY", URIRoot) {
        shuffleShapeIds();
    }

    function removeSelectedShapeId(uint256 index)
    private 
    {
        if (index == remainShapeCounts - 1) {
            shapeIds[index] = 0;
        } else {
            shapeIds[index] = shapeIds[remainShapeCounts - 1];
            shapeIds[remainShapeCounts - 1] = 0;
        }

        remainShapeCounts--;
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
        HNYb_TOKEN = HNYb(_e);
    }

    function collectHoney(uint256 id)
    public 
    {   
        Bee memory bee = bees[id];
        uint32 dayInSeconds = 86400;
        require(ownerOf(id) == msg.sender, "only owner can collect honey.");
        require(block.timestamp > (bee.honeyCollectedLast + dayInSeconds), "honey already collected.");
        HNYb_TOKEN.mint(msg.sender, bee.honeyPerDay);
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
        HNYb_TOKEN.mint(msg.sender, honey);
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }

    function changeTreasuryWallet(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        treasury = payable(_address);
    }

    function getTreasuryWallet() 
    public view returns (address)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        return treasury;
    }

    function changeSettings(uint16 _maxSupply, uint8 _treasuryPercent, uint8 _bankPercent, uint8 _maxMintAmount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        maxSupply = _maxSupply;
        treasuryPercent = _treasuryPercent;
        bankPercent = _bankPercent;
        maxMintAmount = _maxMintAmount;
    }
    
    function updateURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function buy(uint8 quantity) payable external {
        require(quantity > 0, "Quantity must be more than 1.");
        require(quantity <= maxMintAmount, "Quantity must be less than 30.");
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
            uint256 randomId = uint256(keccak256(abi.encodePacked(block.timestamp)));
            uint shape = getBeeShape(randomId);
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
            return 80000000000000000000; // Queen
        }
        else if (shape == 1) {
            return 24000000000000000000; // Karen
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
    returns (uint)
    {
        if (remainShapeCounts == 0) {
            shuffleShapeIds();
        }
        require(remainShapeCounts > 0, "remainShapeCounts must greater than 0");
        uint256 randomIndex = i % remainShapeCounts;
        uint256 j = shapeIds[randomIndex];
        uint result = 6; // Miner
        require(j > 0 && j <= 100, "shapeID must be between 1~100");
        if (j > 97 && j <= 100) {
            result = 0; // Queen
        }
        else if (j > 90 && j <= 97) {
            result = 1; // Karen
        }
        else if (j > 79 && j <= 90) {
            result = 2; // Buzzy
        }
        else if (j > 65 && j <= 79) {
            result = 3; // Tobi
        }
        else if (j > 47 && j <= 65) {
            result = 4; // Demolition
        }
        else if (j > 25 && j <= 47) {
            result = 5; // Excavator
        }

        removeSelectedShapeId(randomIndex);

        return result;
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
            uint256 devCut = balance * treasuryPercent / 100;
            uint256 bankCut = balance * bankPercent / 100;
            treasury.transfer(devCut);
            bank.transfer(bankCut);
        }
    }
}