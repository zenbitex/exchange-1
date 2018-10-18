module Admin
  class Ability
    include CanCan::Ability
    def initialize(user)
      # Admin
      return can :manage, :all if user.admin? && user.role == 1
      # can :read, Order
      # can :read, Trade
      # can :read, Proof
      # can :update, Proof
      # can :manage, Document
      # can :manage, Member
      # can :manage, Ticket
      # can :manage, IdDocument
      # can :manage, TwoFactor
      # can :manage, ColdWallet
      # can :manage, FeeTrade
      # can :menu, Deposit
      # can :manage, ::Deposits::Bank
      # can :manage, ::Deposits::Satoshi
      # can :manage, ::Deposits::Taocoin
      # can :manage, ::Deposits::Ethereum
      # can :menu, Withdraw
      # can :manage, ::Withdraws::Bank
      # can :manage, ::Withdraws::Satoshi
      # can :manage, ::Withdraws::Taocoin
      # can :manage, ::Withdraws::Ethereum

      # PRE Admin
      if user.admin? && user.role == 2
        can :read, Order
        can :read, Trade
        can :read, Proof
        can :update, Proof
        can :manage, Ticket
        can :manage, IdDocument
        can :manage, TwoFactor
        can :manage, Authentication
        can :manage, Contact
        can :manage, Flags
        can :manage, ArbHistory
        can :manage, ArbProfit
      end
      # Guest
      if user.admin? && user.role == 3
        can :manage, IdDocument
      end

      # Normal Member role = 4
    end
  end
end
