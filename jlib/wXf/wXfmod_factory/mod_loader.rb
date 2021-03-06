#
# Class which assists in loading modules, extremely vital for framework functionality
#

require 'find'
  module WXf
  module WXfmod_Factory
    
class ModulePair < Hash
  
  include Framework::Transient
  
  attr_accessor :mods_fn_list
  
  def initialize(type=nil)
    
    # Gives an array of all mods by fullname
    self.mods_fn_list = []
  end
  
  def load_other(name, control)
          begin
              if name.match(/webserver/)
                instance = WXf::WXfconductors::Webserver_Conductor.new(control)       
              elsif name.match(/burp/)  
                instance = WXf::WXfconductors::Burp_Conductor.new(control)               
              end
            end
      return instance
  end
  
  #
  # Adds the module to the ModulePair hash
  #
  def add_module(inst_obj,name)
    inst_obj.framework = framework
    self[name] = inst_obj
  end

  
  def get_name_val(name)
    fetch(name) if has_key?(name)
  end
  
  def load(name)
  instance = get_name_val(name)
  return instance
  
  end
  
    
end


       
      #
      # Class used to create, sort, count modules (mods)
      #
      class Mod_Loader < ModulePair
        
        include Framework::Transient
        
       def initialize(framework, types=FUNCTION_TYPES)
         
         self.lfile_load_list = lfile_load(WXf::ModDatum) 
         
         self.rurls_load_list = rurls_load(WXf::ModRurls) 
         
         self.mod_pair = {} 
           
         self.framework = framework  
           
         # These two must follow eachother     
         type_check
         mod_load(WXf::ModWorkingDir)
         
         self.module_list = module_collect
         
         super(nil)
        
       end
        
       
        #
        # List of valid file based modules. Will have to add payload_mods 
        # when working
        #
        def valid_file_mods
         ["exploit","auxiliary", "buby", "payload"]
        end
               
         
       #
       # Returns true or false based on whether or not
       # a type matches what is in our array of valid file modules 
       # 
       def type_bool?(type)
         valid_file_mods.include?(type)
       end  
       
        #
        # Method checks the type
        #
        def type_check
          FUNCTION_TYPES.each {|mod_type|
            
                  if (type_bool?(mod_type))
                    inst = ModulePair.new(mod_type)
                    self.mod_pair[mod_type] = inst
                    inst.framework = framework
                  end   
           }
        end
          
       
       #
       # Built to collect both aux and file names in a list
       #
       def module_collect
        list = []            
        list.concat(mod_pair['auxiliary'].mods_fn_list)
        list.concat(mod_pair['exploit'].mods_fn_list)
        list.concat(mod_pair['buby'].mods_fn_list)
        list.concat(mod_pair['payload'].mods_fn_list)
        return list.sort
        rescue
       end
       
       
       #
       # Method used to reload some object
       #
       def reload(obj, modname=nil)   
         return if obj == nil
         case obj
           when 'rurls'
             self.rurls_load_list = []
             self.rurls_load_list = rurls_load(WXf::ModRurls) 
           when 'lfiles'
             self.lfile_load_list = []
             self.lfile_load_list = lfile_load(WXf::ModDatum)
         else
           module_reload(obj, modname) 
         end
       end
       
       
       #
       # Gets the process of reload a module restarted
       #
       def module_reload(obj, modname=nil)
         single_mod_load(modname)         
         mod_pair.each do |type, hash|            
           hash.delete_if {|k,v| v == obj}
         end
       end
       
       
       #    
       # Instead of an "all mods_load", lets just load one
       #
       def single_mod_load(filename)        
         bpath = WXf::ModWorkingDir
         proper_name = "#{bpath}/#{filename}.rb"
         if File.exist?(proper_name)
           load_mods(filename, proper_name)          
         end
       end
       
            
       #
       # Loads the files located under the rurls directory
       #
       def rurls_load(base_path)
         hash = {} 
           Find.find(base_path) { |file|
             if File.file?(file) and not file =~ /git/
               nickname = file.sub(base_path, '')
               hash[nickname] = file
             end                       
           }
          return hash
       end
       
       
       #
       # Loads the files located under the lfiles directory
       #
       def lfile_load(base_path)
         hash = {} 
         Find.find(base_path) { |file|
           if File.file?(file) and not file =~ /git/
             nickname = file.sub(base_path, '')
             hash[nickname] = file
            end
         }           
        return hash
      end
         
       
       #
       # Finds all files in the base path (wXf directory)
       #
       def mod_load(base_path)
         Find.find(base_path) do |file|
           if (file =~ /.rb/) and if not (file.match(/svn/))
              data = file.match(/decision_tree\/.+rb/)
              mdata = data.kind_of?(MatchData) ? true : false
              if mdata == false
                path = file.sub(base_path + "/", '').sub(/.rb/, '')
                load_mods(path,file)
              end          
            end
           end
         end
       end
       
           
       #
       # Load the Modules based on their existence within the path
       #
       def load_mods(path,file)         
          begin
            conc = ::Module.new
            conc.module_eval(File.read(file, File.size(file)))
            inst = conc.const_get('WebXploit')
          rescue NameError
            print("Failed to load module: #{path}\n")
          end
           
            if (inst and path)
              inst_obj = inst.new
              # Module types need to have 
              if (inst_obj.respond_to?('type')) and (valid_file_mods.include?("#{inst_obj.type}"))
               type = inst_obj.type
               name = norm_name(type,path)
               init_add_fullname(path, type)
               init_add_module(inst_obj,name,type)
              end
           end
       end
       
       
      #
      # Normalizes the name, essentially removes the "auxiliary/" blah blah
      #    
      def norm_name(type, path)
       name = path.gsub("#{type}/", '')
       return name
      end
      
      
      #
      #
      #
      def init_add_module(inst_obj,name,type)
        mod_pair[type].add_module(inst_obj,name)
      end
      
      
      #
      #
      #
      def init_add_fullname(path,type)
        mod_pair[type].mods_fn_list.push(path)
      end  
       
        
      #
      # Counts for the display when you initially boot up the console
      # 
      def counter(type)
       case type
       when 'auxiliary'
        mod_pair['auxiliary'].count
       when 'exploit'
        mod_pair['exploit'].count  
       when 'buby'
         mod_pair['buby'].count
       when 'payload'
         mod_pair['payload'].count
       end  
        
      end 
  
           
      #
      # Performs some name matching based on input
      #  
      def name_match?(name)
        temp_arry = []
        mod = nil
        if (name)
          name_arry = name.split('/')
          name_dup = name_arry.dup
          name_arry.shift
          mod_arry = name_arry.join('/')
        end
        begin
         valid_file_mods.each do |item|
           if name_dup[0] == item
             temp_arry.push(name_dup[0], mod_arry)
             mod = temp_arry
           end
         end
        end
       return mod
      end

      
      
     
       #
       # Creates an instance of a module and then returns it. 
       #    
       def load(name,control)   
         if not (actv = name_match?(name)) == nil
             mod_pair[actv[0]].load(actv[1])
         else
          load_other(name, control)  
         end

      end

      

      attr_accessor :wxflist_call
      attr_accessor :mod_pair, :module_list, :lfile_load_list, :rurls_load_list
     
    end
  end
end