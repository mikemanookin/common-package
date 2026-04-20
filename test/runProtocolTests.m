function results = runProtocolTests()
    % runProtocolTests - Run all protocol structure validation tests.
    %
    % Usage:
    %   results = runProtocolTests();
    %   disp(results);
    %
    % This script ensures the MATLAB path is set up correctly for the
    % common-package before running the test suite.

    % Determine paths.
    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    srcDir = fullfile(repoRoot, 'src', 'packages', 'base-package');

    % Add source to path (temporarily) so metaclass introspection works.
    addpath(srcDir);
    cleanupObj = onCleanup(@() rmpath(srcDir));

    fprintf('=== Symphony Common Package - Protocol Structure Tests ===\n');
    fprintf('Source: %s\n', srcDir);
    fprintf('Tests:  %s\n\n', testDir);

    % Run the test suite.
    suite = matlab.unittest.TestSuite.fromClass(?ProtocolStructureTest);
    runner = matlab.unittest.TestRunner.withTextOutput('Verbosity', ...
        matlab.unittest.Verbosity.Detailed);

    results = runner.run(suite);

    % Print summary.
    fprintf('\n=== Summary ===\n');
    fprintf('Total:  %d\n', numel(results));
    fprintf('Passed: %d\n', sum([results.Passed]));
    fprintf('Failed: %d\n', sum([results.Failed]));

    if sum([results.Failed]) > 0
        fprintf('\nFailed tests:\n');
        failedIdx = find([results.Failed]);
        for i = 1:numel(failedIdx)
            fprintf('  - %s\n', results(failedIdx(i)).Name);
        end
    end
end
