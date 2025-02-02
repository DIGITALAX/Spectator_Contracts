// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SpectatorAccessControls.sol";
import "./SpectatorLibrary.sol";
import "./SpectatorErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpectatorRewards {
    SpectatorAccessControls public accessControls;
    address public au;
    address[] private _erc20s;
    address[] private _erc721s;

    mapping(address => SpectatorLibrary.SpectatorActivity[])
        private _spectatorActivity;
    mapping(address => SpectatorLibrary.Spectator) private _spectators;
    mapping(address => uint256) private _agentAu;
    mapping(address => uint256) private _thresholdERC20;
    mapping(address => uint256) private _thresholdERC721;

    event Spectated(string data, address spectator, uint256 count);
    event AgentAUUpdated(address agent, uint256 au);
    event SpectatorsAUUpdated(address[] spectators, uint256[] aus);
    event SpectatorBalanceUpdated(address spectator, uint256 balance);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SpectatorErrors.OnlyAdmin();
        }
        _;
    }

    modifier onlyAdminOrAgent() {
        if (
            !accessControls.isAdmin(msg.sender) &&
            !accessControls.isAgent(msg.sender)
        ) {
            revert SpectatorErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyAdminOrAU() {
        if (!accessControls.isAdmin(msg.sender) && au != msg.sender) {
            revert SpectatorErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyHolder() {
        if (!_isHolder()) {
            revert SpectatorErrors.InvalidTokens();
        }
        _;
    }

    constructor(address _accessControls, address _au) {
        accessControls = SpectatorAccessControls(_accessControls);
        au = _au;
    }

    function spectate(string memory data, address agent) public onlyAdmin {
        if (_spectators[msg.sender].initialization == 0) {
            _spectators[msg.sender] = SpectatorLibrary.Spectator({
                initialization: block.timestamp,
                auEarned: 0,
                auClaimed: 0,
                auToClaim: 0
            });
        }
        _spectatorActivity[msg.sender].push(
            SpectatorLibrary.SpectatorActivity({
                blocktimestamp: block.timestamp,
                data: data,
                agent: agent
            })
        );

        emit Spectated(data, msg.sender, _spectatorActivity[msg.sender].length);
    }

    function addAgentAU(
        address agent,
        uint256 balance
    ) public onlyAdminOrAgent {
        _agentAu[agent] += balance;

        emit AgentAUUpdated(agent, balance);
    }

    function manageSpectatorsAU(
        address[] memory spectators,
        uint256[] memory auToClaim
    ) public onlyAdmin {
        if (spectators.length != auToClaim.length) {
            revert SpectatorErrors.BadUserInput();
        }

        for (uint16 i = 0; i < spectators.length; i++) {
            _spectators[spectators[i]].auEarned += auToClaim[i];
            _spectators[spectators[i]].auToClaim += auToClaim[i];
        }
        emit SpectatorsAUUpdated(spectators, auToClaim);
    }

    function updateSpectatorBalance(
        address spectator,
        uint256 balance
    ) public onlyAdminOrAU {
        if (balance < _spectators[msg.sender].auToClaim) {
            revert SpectatorErrors.BalanceInvalid();
        }

        _spectators[msg.sender].auToClaim -= balance;
        _spectators[msg.sender].auClaimed += balance;

        emit SpectatorBalanceUpdated(spectator, balance);
    }

    function _isHolder() internal view returns (bool) {
        bool _holder = false;

        for (uint8 i = 0; i < _erc20s.length; i++) {
            if (
                IERC20(_erc20s[i]).balanceOf(msg.sender) >=
                _thresholdERC20[_erc20s[i]]
            ) {
                _holder = true;

                break;
            }
        }

        if (!_holder) {
            for (uint8 i = 0; i < _erc721s.length; i++) {
                if (
                    IERC721(_erc721s[i]).balanceOf(msg.sender) >=
                    _thresholdERC721[_erc721s[i]]
                ) {
                    _holder = true;

                    break;
                }
            }
        }

        return _holder;
    }

    function getSpectatorCount(
        address spectator
    ) public view returns (uint256) {
        return _spectatorActivity[spectator].length;
    }

    function getSpectatorTimestamp(
        address spectator,
        uint256 count
    ) public view returns (uint256) {
        return _spectatorActivity[spectator][count].blocktimestamp;
    }

    function getSpectatorAgent(
        address spectator,
        uint256 count
    ) public view returns (address) {
        return _spectatorActivity[spectator][count].agent;
    }

    function getSpectatorData(
        address spectator,
        uint256 count
    ) public view returns (string memory) {
        return _spectatorActivity[spectator][count].data;
    }

    function getAgentAUHistory(
        address spectator,
        uint256 count
    ) public view returns (string memory) {
        return _spectatorActivity[spectator][count].data;
    }

    function getSpectatorAUEarned(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auEarned;
    }

    function getSpectatorAUClaimed(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auClaimed;
    }

    function getSpectatorAUToClaim(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auToClaim;
    }

    function getSpectatorInitialization(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].initialization;
    }

    function getERC20s() public view returns (address[] memory) {
        return _erc20s;
    }

    function getERC721s() public view returns (address[] memory) {
        return _erc721s;
    }

    function getERC20Threshold(address erc20) public view returns (uint256) {
        return _thresholdERC20[erc20];
    }

    function getERC721Threshold(address erc721) public view returns (uint256) {
        return _thresholdERC721[erc721];
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SpectatorAccessControls(_accessControls);
    }

    function setAU(address _au) public onlyAdmin {
        au = _au;
    }

    function setERC20s(address[] memory erc20s) public onlyAdmin {
        _erc20s = erc20s;
    }

    function setERC721s(address[] memory erc721s) public onlyAdmin {
        _erc721s = erc721s;
    }

    function setThresholdERC20(
        address erc20,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC20[erc20] = threshold;
    }

    function setThresholdERC721(
        address erc721,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC721[erc721] = threshold;
    }
}
