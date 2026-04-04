classdef Animal < common.sources.Subject
    
    methods
        
        function obj = Animal()
            import symphonyui.core.*;
            import edu.washington.*;
            
            obj.addProperty('species', '', ...
                'type', PropertyType('char', 'row', {'', 'Genus species1', 'Genus species2', 'Genus species3'}), ... 
                'description', 'Species');
            obj.addAllowableParentType([]);
        end
        
    end
    
end

