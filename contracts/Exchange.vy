# @dev Implementation of HarmonySwap liquidity ERC-20 token and k=xy exchange functionality
# @author Anthony Zhang (@uberi)

# based on https://github.com/vyperlang/vyper/blob/47a1a4119e42f8d93d8815fa376d9ee944992a93/examples/tokens/ERC20.vy

from vyper.interfaces import ERC20

implements: ERC20

event AddLiquidity:
    sender: indexed(address)
    token_1_amount: uint256
    token_2_amount: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

decimals: public(uint256)  # number of decimal places our liquidity token is capable of representing

token_1: address(ERC20)  # address of first ERC20 token contract in this trading pair
token_2: address(ERC20)  # address of second ERC20 token contract in this trading pair
token_1_reserve: uint256  # amount of first ERC20 token in reserve
token_2_reserve: uint256  # amount of second ERC20 token in reserve


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])  # public() causes the balanceOf() getter to be created, see https://vyper.readthedocs.io/en/stable/types.html?highlight=getter#mappings
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
minter: address

# TODO: token name and symbol


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.minter = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@external
def addLiquidity(token_1_amount: uint256, max_token_2_amount: uint256) -> uint256:
    if self.total_supply > 0:
        # compute how much of each token we currently have in reserve
        token_1_reserve: uint256 = self.token_1.balanceOf(self)
        token_2_reserve: uint256 = self.token_2.balanceOf(self)

        # receive `token_1_amount` of the first token
        assert self.token_1.transferFrom(msg.sender, self, token_1_amount)

        # compute equivalent amount of the second token at the current exchange rate
        token_2_amount: uint256 = token_1_amount * token_2_reserve / token_1_reserve + 1
        assert token_2_amount <= max_token_2_amount

        # receive `token_2_amount` of the second token
        assert self.token_2.transferFrom(msg.sender, self, token_2_amount)

        # compute the amount of liquidity we've added for this trading pair
        new_liquidity: uint256 = token_1_amount * self.total_supply / token_1_reserve

        # add the new liquidity to the user's balance, and keep track of it in the total liquidity
        self.balances[msg.sender] += new_liquidity
        self.total_supply += new_liquidity
        log AddLiquidity(msg.sender, token_1_amount, token_2_amount)
        log Transfer(ZERO_ADDRESS, msg.sender, self.total_supply)
        return new_liquidity
    else:
        # receive `token_1_amount` of the first token
        assert self.token_1.transferFrom(msg.sender, self, token_1_amount)

        # receive `max_token_2_amount` of the second token
        assert self.token_2.transferFrom(msg.sender, self, max_token_2_amount)

        new_liquidity: uint256 = token_1_amount

        # add the new liquidity to the user's balance, and keep track of it in the total liquidity
        self.balances[msg.sender] = new_liquidity
        self.total_supply = new_liquidity
        log.AddLiquidity(msg.sender, msg.value, token_amount)
        log.Transfer(ZERO_ADDRESS, msg.sender, new_liquidity)
        return new_liquidity


@view
@external
def totalSupply() -> uint256:
    return self.total_supply


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]


@external
def transfer(_to : address, _value : uint256) -> bool:
    # NOTE: `balanceOf` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    # NOTE: `balanceOf` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    # NOTE: `allowances` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)
