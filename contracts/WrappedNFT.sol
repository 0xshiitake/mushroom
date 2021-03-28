pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WrappedNFT is Ownable, ERC721, Pausable {

    event ProxyRegistered(address user, address proxy);

    // Instance of NFT contract
    IERC721 private _baseNFT;

    // Mapping from user address to proxy address
    mapping(address => address) private _proxies;

    // Mapping from tokenID to all past owners
    mapping(uint256 => address[]) pastOwners;

    // Mapping from tokenID to last force buy price
    mapping(uint256 => uint256) lastPrice;

    // DAO Contract Address
    address daoAddress;

    /**
     * @dev Initializes the contract settings
     */
    constructor(address baseNFT)
        public
        ERC721(_wrappedName(baseNFT), _wrappedSymbol(baseNFT))
    {
        _baseNFT = IERC721(baseNFT);
    }

    function _wrappedName(address baseNFT) private pure returns (string memory) {
        string(abi.encodePacked("Wrapped ", IERC721Metadata(baseNFT).name()));
    }

    function _wrappedSymbol(address baseNFT) private pure return (strin memory) {
        string(abi.encodePacked("W", IERC721Metadata(baseNFT).symbol()));
    }

    /**
     * @dev Gets address of the underlying base NFT contract
     */
    function baseNFT()
        public
        view
        returns (address)
    {
        return address(_baseNFT);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function forceBuy(uint256 tokenId) public payable {        
        require(_exists(tokenId), "Wrapped NFT: Attempted Force Buy of nonexistent NFT");

        // Require purchase price is 2x last sale price
        uint256 purchasePrice = lastPrice[tokenId] * 2;
        require(msg.value > purchasePrice, "Wrapped NFT: Insufficent funds to force by NFT");

        // Refund any excess payment
        payable(_msgSender()).transfer(msg.value - purchasePrice);

        // counter to track remaining funds left to distribute
        uint256 remainingFunds = purchasePrice;

        // Give portion of purchase amount to all past owners
        uint256 numPastOwners = pastOwners[tokenId].length;
        uint256 fundsPerPastOwner = purchasePrice / 10 / numPastOwners; // TODO: Parameterize this
        for (uint i = 0; i < numPastOwners; i++) {
            remainingFunds = remainingFunds - fundsPerPastOwner;
            payable(pastOwners[tokenId][i]).transfer(fundsPerPastOwner);
        }

        // Give portion of purchase amount to the dao
        uint256 fundsToDao = purchasePrice / 10; // TODO: Parameterize this
        remainingFunds = remainingFunds - fundsToDao;
        payable(daoAddress).transfer(fundsToDao);

        // Give remaining amount to current owner
        address currentOwner = ownerOf(tokenId);
        payable(currentOwner).transfer(remainingFunds);

        // Add current owner to list of past owners
        pastOwners[tokenId].push(currentOwner); 

        // Transfer NFT from current owner to force buyer
        transferFrom(currentOwner, _msgSender(), tokenId);

        // Update last sale price
        lastPrice[tokenId] = purchasePrice;

        // TODO: Mint Dao Tokens
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return IERC721Metadata(_baseNFT).tokenURI(tokenId);
    }

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    /**
     * @dev Mints a wrapped NFT
     */
    function mint(uint256 tokenId)
        public
        whenNotPaused
    {
        address sender = _msgSender();
        _baseNFT.transferFrom(sender, address(this), tokenId);
        _mint(sender, tokenId);



        // TODO: Figure out proxy stuff later
        // UserProxy proxy = UserProxy(_proxies[sender]);
        // require(proxy.transfer(address(_punkContract), punkIndex), "PunkWrapper: transfer fail");
    }

    // /**
    //  * @dev Internal function to transfer ownership of a given punk index to another address
    //  */
    // function _transferFrom(address from, address to, uint256 punkIndex)
    //     internal
    //     whenNotPaused
    // {
    //     super._transferFrom(from, to, punkIndex);
    // }

    // TODO: Deal with Proxy stuff later
    //
    // /**
    //  * @dev Registers proxy
    //  */
    // function registerProxy()
    //     public
    // {
    //     address sender = _msgSender();

    //     require(_proxies[sender] == address(0), "PunkWrapper: caller has registered the proxy");

    //     address proxy = address(new UserProxy());

    //     _proxies[sender] = proxy;

    //     emit ProxyRegistered(sender, proxy);
    // }

    // /**
    //  * @dev Gets proxy address
    //  */
    // function proxyInfo(address user)
    //     public
    //     view
    //     returns (address)
    // {
    //     return _proxies[user];
    // }
}