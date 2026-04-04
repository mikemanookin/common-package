classdef Preparation < common.sources.Preparation
    
    methods
        
        function obj = Preparation()
            import symphonyui.core.*;
            
            obj.addAllowableParentType('io.sources.animal.Animal');
        end
        
    end
    
end

