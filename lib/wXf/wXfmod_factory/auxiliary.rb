module WXf
module WXfmod_Factory
  
  class Auxiliary < Mod_Factory
 
    attr_accessor :type
    
    def initialize(hash_info ={})
      super
    end

  
    #
    # Defines the type of module
    #
    def type
      AUXILIARY
    end
    
    def dis_required_opts
      # Display the commands
      tbl = WXf::WXfui::Console::Prints::PrintTable.new(
      'Justify' => 4,
      'Columns' =>
      [
       'Name',
       'Current Setting',
       'Required',
       'Description',
                              
      ])
                  
     self.options.sorted.each { |item|
     name, option = item
     val = datahash[name] || option.data.to_s
     tbl.add_ritems([name,val, "#{option.required}", option.desc]) 
     }
     tbl.prnt
   end
   
   def usage       
     $stderr.puts("\n"+"Auxiliary Module options:")
     dis_required_opts   
   end
   
  end
  
end end