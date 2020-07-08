# @dev Implementation of ERC-20 token standard.
# @author Takayuki Jimba (@yudetamago)
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

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

balanceOf: public(HashMap[address, uint256])  # public() causes the balanceOf() getter to be created, see https://vyper.readthedocs.io/en/stable/types.html?highlight=getter#mappings
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
minter: address


@external
def __init__(_decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
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
        # TODO: why?
        assert self.factory != ZERO_ADDRESS and self.token_1 != ZERO_ADDRESS and self.token_2 != ZERO_ADDRESS
        assert self.factory.getExchange(self.token) == self

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
    """
    @dev Total number of tokens in existence.
    """
    return self.total_supply


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner The address which owns the funds.
    @param _spender The address which will spend the funds.
    @return An uint256 specifying the amount of tokens still available for the spender.
    """
    return self.allowances[_owner][_spender]


@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: `balanceOf` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: `balanceOf` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    # NOTE: `allowances` values are unsigned, so underflows cause the transaction to revert on insufficient balance
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)
