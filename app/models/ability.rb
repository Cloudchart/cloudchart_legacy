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
      cannot :token, Chart
    elsif user && user.is_god?
      can :manage, :all
    else
      can :read, :all
      can :manage, Chart, id: user.accesses.editables.map(&:chart_id)
      can :token, Chart, id: user.accesses.owners.map(&:chart_id)
    end
  end
end
