class Ability
  include CanCan::Ability
  
  def initialize(user, charts = nil)
    # Charts with tokens
    if charts && charts.any?
      can :manage, Chart, id: charts.map(&:id)
    end
    
    # User abilities
    if !user
      can :read, :all
    elsif user && user.is_god?
      can :manage, :all
    else
      can :read, :all
      can :manage, Chart, user_id: user.id
    end
  end
end
