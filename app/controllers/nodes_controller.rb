class NodesController < ApplicationController
  def index
    @nodes = Node.charts
    
    respond_to do |format|
      format.json { render json: @nodes }
    end
  end
  
  def show
    respond_to do |format|
      format.json {
        render json: { 
          root_id: @node.id,
          ancestor_ids: @node.ancestor_ids,
          nodes: @node.descendant_and_ancestor_nodes,
          links: @node.descendant_links_and_self,
          identities: @node.descendant_identities_and_self
        }
      }
    end
  end
  
  def update
    # Ids mapping
    mapping = {}
    
    # Update nodes
    nodes = resource_params[:nodes] || []
    node_ids = []
    nodes.each do |attrs|
      if attrs[:id] =~ /^_[0-9]+$/
        node = @node.organization.nodes.create!(attrs)
        mapping[attrs[:id]] = node.id
      else
        node = Node.find(attrs[:id])
        node.ensure_attributes(attrs)
      end
      
      node_ids << node.id
    end
    
    # Remove nodes
    previous_node_ids = @node.descendant_and_ancestor_nodes.map(&:id)
    Node.in(id: (previous_node_ids - node_ids)).destroy_all
    
    # Update links
    links = resource_params[:links] || []
    link_ids = []
    links.each do |attrs|
      if attrs[:id] =~ /^_[0-9]+$/
        # Normalize attributes
        [:parent_node_id, :child_node_id].each do |attr|
          if attrs[attr] =~ /^_[0-9]+$/
            attrs[attr] = mapping[attrs[attr]]
          end
        end
        
        link = @node.organization.links.create(attrs)
      else
        link = Link.find(attrs[:id])
        link.ensure_attributes(attrs)
      end
      
      link_ids << link.id
    end
    
    # Remove links
    previous_link_ids = @node.descendant_links_and_self.map(&:id)
    Link.in(id: (previous_link_ids - link_ids)).destroy_all
    
    respond_to do |format|
      format.json {
        render json: {}
      }
    end
  end
  
  private
  
    def preload
      @node = Node.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:node]
    end
end
