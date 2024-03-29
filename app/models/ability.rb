class Ability
  include CanCan::Ability
  
  def initialize(user, token = nil)
    # User abilities
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
      
      # TODO: Person
      can :manage, Person, owner_id: user.id
    end
    
    # Token abilities
    if token
      case token.type
      when "Person"
        # Allow token abilities only for local persons
        can token.level.to_sym, token.type.constantize, id: token.entity_id if token.entity.local?
      else
        can token.level.to_sym, token.type.constantize, id: token.entity_id
      end
    end
  end
end
