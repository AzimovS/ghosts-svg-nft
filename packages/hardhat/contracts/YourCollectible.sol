pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './ToColor.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address payable public constant recipient =
    payable(0xe5F7e675A48b180eD2C81d0211E23b44ECE9c926);

  uint256 public constant limit = 100;
  uint256 public constant curve = 105;
  uint256 public price = 0.002 ether;

  constructor() public ERC721("Ghosts", "GHOO") {
    // RELEASE THE Ghosts!
  }

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => bytes3) public eyeColor;

  function mintItem()
      public
      payable
      returns (uint256)
  {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");

      price = (price * curve) / 100;

      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      eyeColor[id] = bytes2(predictableRandom[2] >> 16) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[0]));

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      return id;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Ghost #',id.toString()));
      string memory description = string(abi.encodePacked('This Ghost is the color #',color[id + 1].toColor(),' with eye color of ',eyeColor[id].toColor(),'!!!'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"},{"trait_type": "eye_color", "value": "#',
                              eyeColor[id].toColor(),
                              '"}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
        '<g transform="translate(45.000000,360.000000) scale(0.05000,-0.05000)" fill="#',
        eyeColor[id].toColor(),
        '" stroke="none">',
        '<path fill="#',
        color[id].toColor(),
        '" d="M2577 7180 c-565 -86 -1099 -353 -1463 -732 -413 -428 -656 -1098 -868 -2388 -211 -1283 -296 -2568 -210 -3170 60 -415 197 -634 420 -670 134 -22 248 23 518 203 280 187 325 186 591 -9 151 -111 231 -160 312 -190 190 -72 337 -44 643 119 217 117 279 141 365 142 91 0 152 -29 336 -158 215 -151 317 -200 444 -213 134 -14 252 25 526 172 226 121 271 138 375 139 76 0 86 -3 165 -43 46 -23 156 -95 245 -160 245 -179 354 -229 484 -220 332 24 487 448 466 1278 -6 257 -13 374 -41 685 -88 971 -341 2422 -565 3242 -183 672 -363 1048 -624 1308 -127 126 -247 214 -421 309 -540 294 -1197 432 -1698 356z m633 -261 c283 -40 556 -126 835 -264 227 -112 336 -186 466 -315 206 -204 344 -472 494 -955 253 -815 546 -2459 640 -3583 61 -736 28 -1247 -95 -1460 -77 -132 -145 -119 -420 81 -278 203 -399 259 -560 259 -144 0 -236 -32 -509 -177 -344 -184 -386 -183 -669 12 -260 181 -355 223 -503 223 -127 0 -192 -22 -445 -151 -126 -64 -254 -124 -284 -133 -138 -41 -200 -16 -495 198 -228 166 -377 200 -562 131 -83 -31 -115 -50 -312 -178 -276 -179 -335 -181 -416 -12 -129 268 -154 881 -74 1845 49 607 139 1289 244 1865 150 817 320 1351 543 1705 238 376 714 711 1210 850 313 88 584 106 912 59z"/>',
        '<path  d="M3574 5505 c-170 -37 -324 -160 -401 -320 -82 -172 -81 -352 1 -520 99 -200 302 -327 526 -326 168 0 305 56 420 171 114 113 170 252 170 417 0 168 -52 294 -170 414 -145 147 -346 208 -546 164z"/>',
        '<path  d="M1900 5474 c-209 -56 -370 -218 -426 -427 -8 -29 -14 -96 -14 -149 0 -173 61 -312 191 -433 119 -111 262 -161 429 -152 120 7 201 34 299 101 256 174 333 512 178 786 -68 122 -221 238 -363 274 -77 20 -220 20 -294 0z"/>',
        '</g>'
      ));

    return render;
  }



  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
