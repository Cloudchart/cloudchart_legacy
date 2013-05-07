class Ability
  include CanCan::Ability
  
  # User abilities
  def initialize(user)
    if !user
      can :read, :all
    elsif user && user.is_god?
      can :manage, :all
      can :token, :all
    else
      can :read, :all
      can :manage, Organization, id: user.accesses.organizations.editables.map(&:entity_id)
      can :token, Organization, id: user.accesses.organizations.owners.map(&:entity_id)
      can :manage, Node, id: user.accesses.nodes.editables.map(&:entity_id)
      can :token, Node, id: user.accesses.nodes.owners.map(&:entity_id)
    end
  end
end
