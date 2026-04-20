function report = auditDependencies(verbose)
    % auditDependencies - Scan common-package for external namespace references.
    %
    % Checks all .m files under src/ for references to namespaces that belong
    % to external repositories (riekelab-package, manookin-package). The goal
    % is to ensure common-package is autonomous and does not depend on code
    % outside this repository (other than the Symphony core app itself).
    %
    % Usage:
    %   report = auditDependencies();       % quiet mode: returns struct
    %   report = auditDependencies(true);   % verbose: also prints to console
    %
    % Output:
    %   report.clean       - true if no external references found
    %   report.totalFiles  - number of .m files scanned
    %   report.violations  - struct array with fields: file, line, match, pattern

    if nargin < 1
        verbose = true;
    end

    % --- Configuration ---------------------------------------------------
    % Patterns that indicate an external dependency. Each entry is a struct
    % with a regex pattern and a human-readable description.
    externalPatterns = {
        struct('pattern', 'edu\.washington\.riekelab', ...
               'description', 'riekelab-package namespace')
        struct('pattern', 'manookinlab\.', ...
               'description', 'manookin-package namespace')
    };

    % Allowed references (these are false positives, e.g., in comments
    % documenting migration history). Add patterns here to suppress them.
    allowlist = {
        '^\s*%'   % Lines that are pure comments
    };

    % --- Find files -------------------------------------------------------
    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    srcDir = fullfile(repoRoot, 'src');

    if ~isfolder(srcDir)
        error('auditDependencies:noSrc', 'Source directory not found: %s', srcDir);
    end

    mFiles = dir(fullfile(srcDir, '**', '*.m'));
    totalFiles = numel(mFiles);

    if verbose
        fprintf('=== Dependency Audit: common-package ===\n');
        fprintf('Scanning %d .m files in %s\n\n', totalFiles, srcDir);
    end

    % --- Scan files -------------------------------------------------------
    violations = [];

    for f = 1:totalFiles
        filePath = fullfile(mFiles(f).folder, mFiles(f).name);
        relPath = strrep(filePath, [repoRoot filesep], '');

        src = fileread(filePath);
        lines = strsplit(src, '\n');

        for lineNum = 1:numel(lines)
            line = lines{lineNum};

            % Check each external pattern.
            for p = 1:numel(externalPatterns)
                pat = externalPatterns{p};
                match = regexp(line, pat.pattern, 'match', 'once');

                if ~isempty(match)
                    % Check allowlist.
                    isAllowed = false;
                    for a = 1:numel(allowlist)
                        if ~isempty(regexp(line, allowlist{a}, 'once'))
                            isAllowed = true;
                            break;
                        end
                    end

                    if ~isAllowed
                        v.file = relPath;
                        v.line = lineNum;
                        v.match = strtrim(line);
                        v.pattern = pat.description;

                        if isempty(violations)
                            violations = v;
                        else
                            violations(end+1) = v; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end

    % --- Report -----------------------------------------------------------
    report.clean = isempty(violations);
    report.totalFiles = totalFiles;
    report.violations = violations;

    if verbose
        if report.clean
            fprintf('PASS: No external namespace references found.\n');
            fprintf('      common-package is autonomous.\n');
        else
            fprintf('FAIL: Found %d external reference(s):\n\n', numel(violations));
            for i = 1:numel(violations)
                v = violations(i);
                fprintf('  [%s] %s:%d\n', v.pattern, v.file, v.line);
                fprintf('    %s\n\n', v.match);
            end
            fprintf('These references must be replaced with common-package equivalents\n');
            fprintf('or removed to ensure the package is self-contained.\n');
        end
        fprintf('\nFiles scanned: %d\n', totalFiles);
    end
end
