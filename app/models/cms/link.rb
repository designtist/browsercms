module Cms
class Link < ActiveRecord::Base
  namespaces_table
  acts_as_content_block :connectable => false
  
  named_scope :named, lambda{|name| {:conditions => ["#{table_name}.name = ?", name]}}
  
  has_one :section_node, :as => :node, :dependent => :destroy, :class_name => 'Cms::SectionNode'
  
  validates_presence_of :name

  def section_id
    section ? section.id : nil
  end
  
  def section
    section_node ? section_node.section : nil
  end
  
  def section_id=(sec_id)
    self.section = Cms::Section.find(sec_id)
  end
  
  def section=(sec)
    if section_node
      section_node.move_to_end(sec)
    else
      build_section_node(:node => self, :section => sec)
    end      
  end

  #needed by menu_helper
  def path
    url
  end

end
end