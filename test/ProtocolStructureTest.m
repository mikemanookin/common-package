classdef ProtocolStructureTest < matlab.unittest.TestCase
    % ProtocolStructureTest - Validates that all protocols in +common/+protocols
    % satisfy the structural contracts defined in spec/specs/protocol-structure.md.
    %
    % This test uses MATLAB metaclass introspection so it does NOT require
    % a running Symphony rig or Stage server. It validates:
    %   1. Every concrete protocol inherits from common.protocols.CommonProtocol.
    %   2. Every protocol defines the six required abstract properties.
    %   3. Stage protocols inherit from CommonStageProtocol and define createPresentation.
    %   4. Class files parse without errors.
    %
    % Run with:
    %   results = runtests('ProtocolStructureTest');
    %   disp(results);

    properties (Constant)
        % Required abstract properties that every CommonProtocol subclass must define.
        REQUIRED_PROPERTIES = {'amp', 'preTime', 'stimTime', 'tailTime', ...
                               'numberOfAverages', 'interpulseInterval'};

        % The base classes (not tested as concrete protocols).
        BASE_CLASSES = {'common.protocols.CommonProtocol', ...
                        'common.protocols.CommonStageProtocol'};
    end

    properties (TestParameter)
        protocolName = ProtocolStructureTest.discoverProtocols();
    end

    methods (Static)
        function names = discoverProtocols()
            % Discover all .m files in +common/+protocols and return their
            % fully qualified class names. Excludes abstract base classes.
            %
            % This method is called at test-parameterization time. It finds
            % protocols by scanning the filesystem rather than relying on
            % MATLAB path state.

            names = {};

            % Locate the +protocols directory relative to this test file.
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);  % common-package/
            protocolDir = fullfile(repoRoot, 'src', 'packages', 'base-package', ...
                                  '+common', '+protocols');

            if ~isfolder(protocolDir)
                warning('ProtocolStructureTest:noDir', ...
                    'Protocol directory not found: %s', protocolDir);
                return;
            end

            files = dir(fullfile(protocolDir, '*.m'));
            baseClasses = ProtocolStructureTest.BASE_CLASSES;

            for i = 1:numel(files)
                [~, className] = fileparts(files(i).name);
                fqn = ['common.protocols.' className];

                % Skip known abstract base classes.
                if ismember(fqn, baseClasses)
                    continue;
                end

                names{end+1} = fqn; %#ok<AGROW>
            end

            if isempty(names)
                warning('ProtocolStructureTest:noProtocols', ...
                    'No concrete protocols found in %s', protocolDir);
            end
        end
    end

    methods (Test)

        function testClassParses(testCase, protocolName)
            % Verify that the class file can be loaded by the MATLAB metaclass
            % system without parse errors.
            try
                mc = meta.class.fromName(protocolName);
                testCase.verifyNotEmpty(mc, ...
                    sprintf('meta.class.fromName returned empty for %s. The file may have a parse error.', protocolName));
            catch ME
                testCase.verifyFail(sprintf('Failed to load metaclass for %s: %s', ...
                    protocolName, ME.message));
            end
        end

        function testInheritsFromCommonProtocol(testCase, protocolName)
            % Every concrete protocol must inherit (directly or indirectly)
            % from common.protocols.CommonProtocol.
            mc = meta.class.fromName(protocolName);
            if isempty(mc)
                testCase.assumeFail('Metaclass not available; skipping.');
            end

            superNames = ProtocolStructureTest.getAllSuperclassNames(mc);
            testCase.verifyTrue(ismember('common.protocols.CommonProtocol', superNames), ...
                sprintf('%s does not inherit from common.protocols.CommonProtocol.', protocolName));
        end

        function testRequiredPropertiesExist(testCase, protocolName)
            % Every concrete protocol must define all required properties.
            % They may be concrete or Dependent, but they must exist.
            mc = meta.class.fromName(protocolName);
            if isempty(mc)
                testCase.assumeFail('Metaclass not available; skipping.');
            end

            allPropNames = {mc.PropertyList.Name};
            for i = 1:numel(testCase.REQUIRED_PROPERTIES)
                propName = testCase.REQUIRED_PROPERTIES{i};
                testCase.verifyTrue(ismember(propName, allPropNames), ...
                    sprintf('%s is missing required property ''%s''.', protocolName, propName));
            end
        end

        function testRequiredPropertiesNotAbstract(testCase, protocolName)
            % Required properties must not remain abstract in concrete protocols.
            mc = meta.class.fromName(protocolName);
            if isempty(mc)
                testCase.assumeFail('Metaclass not available; skipping.');
            end

            % If the class itself is abstract, skip this check.
            if mc.Abstract
                testCase.assumeFail(sprintf('%s is abstract; skipping concreteness check.', protocolName));
            end

            for i = 1:numel(testCase.REQUIRED_PROPERTIES)
                propName = testCase.REQUIRED_PROPERTIES{i};
                propMeta = findobj(mc.PropertyList, 'Name', propName);
                if ~isempty(propMeta)
                    testCase.verifyFalse(propMeta.Abstract, ...
                        sprintf('%s.%s is still abstract. It must be defined concretely.', ...
                        protocolName, propName));
                end
            end
        end

        function testStageProtocolContract(testCase, protocolName)
            % Stage protocols must: (a) inherit from CommonStageProtocol, and
            % (b) implement createPresentation.
            mc = meta.class.fromName(protocolName);
            if isempty(mc)
                testCase.assumeFail('Metaclass not available; skipping.');
            end

            superNames = ProtocolStructureTest.getAllSuperclassNames(mc);
            isStage = ismember('common.protocols.CommonStageProtocol', superNames);

            if ~isStage
                % Non-stage protocol; nothing extra to check.
                return;
            end

            % Find createPresentation in the method list.
            methodMeta = findobj(mc.MethodList, 'Name', 'createPresentation');
            testCase.verifyNotEmpty(methodMeta, ...
                sprintf('%s inherits from CommonStageProtocol but does not define createPresentation.', protocolName));

            if ~isempty(methodMeta) && ~mc.Abstract
                testCase.verifyFalse(methodMeta.Abstract, ...
                    sprintf('%s.createPresentation is still abstract.', protocolName));
            end
        end

        function testPropertyCommentsExist(testCase, protocolName)
            % Each required property should have a comment (which becomes the
            % UI label in Symphony). This is a soft check (warning, not failure).
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);
            protocolDir = fullfile(repoRoot, 'src', 'packages', 'base-package', ...
                                  '+common', '+protocols');

            parts = strsplit(protocolName, '.');
            fileName = fullfile(protocolDir, [parts{end} '.m']);

            if ~isfile(fileName)
                return;
            end

            src = fileread(fileName);

            % Check that each declared required property has a trailing comment.
            for i = 1:numel(testCase.REQUIRED_PROPERTIES)
                propName = testCase.REQUIRED_PROPERTIES{i};
                % Match: propName followed by optional '= ...' then '%' comment
                pattern = [propName '\s*(?:=[^%\n]*)?\s*%'];
                if isempty(regexp(src, pattern, 'once'))
                    % Only warn; not all properties need comments (e.g., amp).
                    % But timing properties and numberOfAverages should have them.
                    if ~strcmp(propName, 'amp')
                        testCase.log(matlab.unittest.Verbosity.Terse, ...
                            sprintf('SUGGESTION: %s.%s has no descriptive comment (becomes UI label).', ...
                            protocolName, propName));
                    end
                end
            end
        end

        function testClassIsNotAbstract(testCase, protocolName)
            % Concrete protocols should not be marked Abstract.
            mc = meta.class.fromName(protocolName);
            if isempty(mc)
                testCase.assumeFail('Metaclass not available; skipping.');
            end

            testCase.verifyFalse(mc.Abstract, ...
                sprintf('%s is still abstract. Concrete protocols should not be Abstract.', protocolName));
        end

        function testOneClassPerFile(testCase, protocolName)
            % INV-6: Each .m file must contain exactly one classdef whose
            % name matches the file name.
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);
            protocolDir = fullfile(repoRoot, 'src', 'packages', 'base-package', ...
                                  '+common', '+protocols');

            parts = strsplit(protocolName, '.');
            className = parts{end};
            fileName = fullfile(protocolDir, [className '.m']);

            if ~isfile(fileName)
                return;
            end

            src = fileread(fileName);

            % Count classdef declarations.
            classdefMatches = regexp(src, '^\s*classdef\s', 'lineanchors');
            testCase.verifyEqual(numel(classdefMatches), 1, ...
                sprintf('%s.m contains %d classdef declarations (expected 1).', ...
                className, numel(classdefMatches)));

            % Verify the classdef name matches the file name.
            nameMatch = regexp(src, ['classdef\s+(?:\([^)]*\)\s+)?' className '\s'], 'once');
            testCase.verifyNotEmpty(nameMatch, ...
                sprintf('classdef name in %s.m does not match the file name.', className));
        end

        function testNoExternalNamespaceReferences(testCase, protocolName)
            % Protocols in common-package should not reference external
            % namespaces (edu.washington.riekelab, manookinlab).
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);
            protocolDir = fullfile(repoRoot, 'src', 'packages', 'base-package', ...
                                  '+common', '+protocols');

            parts = strsplit(protocolName, '.');
            fileName = fullfile(protocolDir, [parts{end} '.m']);

            if ~isfile(fileName)
                return;
            end

            src = fileread(fileName);

            % Check for known external namespaces.
            externalPatterns = {'edu\.washington\.riekelab', 'manookinlab\.'};
            for i = 1:numel(externalPatterns)
                match = regexp(src, externalPatterns{i}, 'match', 'once');
                testCase.verifyEmpty(match, ...
                    sprintf('%s contains external reference: %s', protocolName, match));
            end
        end
    end

    methods (Static, Access = private)
        function names = getAllSuperclassNames(mc)
            % Recursively collect all superclass names for a meta.class object.
            names = {};
            supers = mc.SuperclassList;
            for i = 1:numel(supers)
                names{end+1} = supers(i).Name; %#ok<AGROW>
                names = [names, ProtocolStructureTest.getAllSuperclassNames(supers(i))]; %#ok<AGROW>
            end
            names = unique(names);
        end
    end
end
